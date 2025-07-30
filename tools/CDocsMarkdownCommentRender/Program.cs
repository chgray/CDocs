using System.Diagnostics;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;
using CommandLine;

/// <summary>
/// CDocs Markdown Comment Renderer - A Pandoc filter for processing code blocks and images
/// in CDocs documentation. Supports bidirectional conversion between code blocks and images,
/// and can adjust header levels dynamically.
/// </summary>
namespace Pandoc.Comment.Render
{
    /// <summary>
    /// Extension methods for traversing JSON node hierarchies recursively
    /// </summary>
    public static class JsonEnumerator
    {
        /// <summary>
        /// Recursively yields all child nodes from a JsonNode tree structure
        /// </summary>
        /// <param name="node">The root JsonNode to traverse</param>
        /// <returns>An enumerable of all child JsonNodes</returns>
        public static IEnumerable<JsonNode> JsonNodeChildren(this JsonNode? node)
        {
            // Handle JsonObject - iterate through key-value pairs
            if (node is JsonObject jObject)
            {
                foreach (var me in jObject)
                {
                    if (me.Value != null)
                    {
                        yield return me.Value;
                        // Recursively get children of this value
                        foreach (var child in me.Value.JsonNodeChildren())
                            yield return child;
                    }
                }
            }
            // Handle JsonArray - iterate through array elements
            else if (node is JsonArray jArray)
            {
                foreach (var item in jArray)
                {
                    if (item != null)
                    {
                        yield return item;
                        // Recursively get children of this item
                        foreach (var child in item.JsonNodeChildren())
                            yield return child;
                    }
                }
            }
            // Base case: primitive values or null nodes have no children
            else
                yield break;
        }
    }
    internal class Program
    {
        /// <summary>
        /// Command line options for the CDocs renderer
        /// </summary>
        public class Options
        {
            [Option('i', "input", Required = false, HelpText = "Input File")]
            public string? InputFile { get; set; }

            [Option('o', "output", Required = false, HelpText = "Output File")]
            public string? OutputFile { get; set; }

            [Option('r', "reverse", Required = false, Default = false, HelpText = "Reverse Direction - convert images back to code blocks, envVar=CDOCS_REVERSE")]
            public bool Reverse { get; set; }

            [Option('t', "tab", Required = false, Default = null, HelpText = "Tab header levels by <n>, envVar=CDOCS_TAB")]
            public int TabIncrement { get; set; }

            [Option('f', "filterMode", Required = false, Default = false, HelpText = "Pandoc Filter Mode - read from stdin/write to stdout, envVar=CDOCS_FILTER")]
            public bool FilterMode { get; set; }


        }

        /// <summary>
        /// Represents a Pandoc AST object with type and content
        /// </summary>
        class PandocObject
        {
            /// <summary>The type of the Pandoc object (e.g., "Image", "Para", "CodeBlock")</summary>
            public string t { get; set; } = string.Empty;

            /// <summary>The content/children of the Pandoc object</summary>
            public object? c { get; set; }

            public PandocObject() { }

            /// <summary>
            /// Creates a new PandocObject with specified type and content
            /// </summary>
            /// <param name="_t">The Pandoc object type</param>
            /// <param name="_c">The content string</param>
            public PandocObject(string _t, string _c)
            {
                t = _t;
                c = _c;
            }

            /// <summary>
            /// Serializes this PandocObject to JSON string
            /// </summary>
            /// <returns>JSON representation of this object</returns>
            public string ToJson()
            {
                var options = new JsonSerializerOptions
                {
                    WriteIndented = true,
                    TypeInfoResolver = new DefaultJsonTypeInfoResolver()
                };

                string jsonString = JsonSerializer.Serialize(this);
                return jsonString;
            }
        }


        /// <summary>
        /// Helper class for CDocs Pandoc operations including file management,
        /// code block processing, and image conversion
        /// </summary>
        class CDocsPandocHelper
        {
            /// <summary>
            /// Finds the content directory where generated media files are stored
            /// </summary>
            /// <returns>Path to the orig_media directory</returns>
            static string FindContentDirectory()
            {
                return Path.Combine((FindDBDirectory()), "orig_media");
            }

            /// <summary>
            /// Locates the CDocs database directory by searching for .CDocs.config file
            /// </summary>
            /// <returns>Path to the directory containing .CDocs.config</returns>
            static string FindDBDirectory()
            {
                // Search upward from current directory for .CDocs.config file
                string? configDir = System.IO.Directory.GetCurrentDirectory();
                for(;;)
                {
                    string root = Path.Combine(configDir, ".CDocs.config");
                    Console.Error.WriteLine($"CDOCS_FILTER: Looking for config file in {root}");

                    if (File.Exists(root))
                    {
                        Console.Error.WriteLine($"CDOCS_FILTER: FoundConfig {configDir}");
                        return configDir;
                    }

                    // Move up one directory level
                        configDir = Path.GetDirectoryName(configDir);
                    if(String.IsNullOrEmpty(configDir))
                    {
                        Console.Error.WriteLine("CDOCS_FILTER: Unable to locate .CDocs.config");
                        Environment.Exit(-122);
                    }
                }
            }
            /// <summary>
            /// Creates a relative path for the given file within the project structure
            /// </summary>
            /// <param name="file">The file path to make relative</param>
            /// <param name="db">Database directory (unused in current implementation)</param>
            /// <returns>Relative path from current working directory</returns>
            static string CreeateHackyDirectPath(string file, string db)
            {
                // Get the full path of the file
                file = new FileInfo(file).FullName;

                // Find our CDocs root directory
                string configDir = FindDBDirectory();

                Console.Error.WriteLine($"CDOCS_FILTER:    CWD : {Directory.GetCurrentDirectory()}");
                Console.Error.WriteLine($"CDOCS_FILTER: CONFIG : {configDir}");
                Console.Error.WriteLine($"CDOCS_FILTER:    FILE: {file}");

                string? dirName = Path.GetDirectoryName(file);
                if (dirName == null)
                    return file; // fallback to original file if can't get directory

                // Create relative path from current directory to the file
                string bits = Path.GetRelativePath(Directory.GetCurrentDirectory(), dirName);
                Console.Error.WriteLine($"CDOCS_FILTER:     REL: {bits}");
                bits += $"{Path.DirectorySeparatorChar}{Path.GetFileName(file)}";
                return bits;
            }
            /// <summary>
            /// Searches for Image objects within a JSON node tree and returns the image path
            /// </summary>
            /// <param name="n">The JSON node to search within</param>
            /// <returns>The image path if found, null otherwise</returns>
            string? FindImage(JsonNode? n)
            {
                if (n == null) return null;

                // Traverse all child nodes looking for Image objects
                foreach (var a in n.JsonNodeChildren().ToArray())
                {
                    if (null == a)
                        continue;

                    if (a is JsonObject)
                    {
                        var t = a["t"];
                        if (null != t)
                        {
                            var blah = t.GetValue<string>();

                            // Check if this is an Image Pandoc object
                            if(0 == blah.CompareTo("Image"))
                            {
                                // Extract the image path from the Pandoc Image structure
                                // Image structure: ["Image", [attr], [inlines], [url, title]]
                                string? me = a["c"]?[2]?[0]?.ToString();
                                return me;
                            }
                        }
                    }
                }
                return null;
            }
            /// <summary>
            /// Locates the scripts directory containing CDocs rendering scripts
            /// </summary>
            /// <returns>Path to scripts directory, or null if not found</returns>
            private string? FindScriptsDirectory()
            {
                // Start from the current executable location and search upward
                string? modulePath = Assembly.GetExecutingAssembly().Location;
                for(; ; )
                {
                    if (string.IsNullOrEmpty(modulePath))
                        return null;

                    string scriptDir = Path.Combine(modulePath, "scripts");
                    if (Directory.Exists(scriptDir))
                        return scriptDir;

                    // Move up one directory level
                    modulePath = Path.GetDirectoryName(modulePath);
                    if (String.IsNullOrEmpty(modulePath))
                        return null;
                }
            }
            /// <summary>
            /// Main recursive function that processes JSON nodes for code block to image conversion
            /// and reverse image to code block conversion
            /// </summary>
            /// <param name="options">Command line options</param>
            /// <param name="n">Current JSON node being processed</param>
            private void Recurse(Options options, JsonNode? n)
            {
                if (n == null) return;

                // Process all child nodes recursively
                foreach (var a in n.JsonNodeChildren().ToArray())
                {
                    if (null == a)
                        continue;

                    try
                    {
                        if (a is JsonObject)
                        {
                            var t = a["t"];

                            if (null != t)
                            {
                                var blah = t.GetValue<string>();

                                // Forward direction: Convert CodeBlock to Image
                                if (blah.Equals("CodeBlock") && !options.Reverse)
                                {
                                    // Skip if no language/type specified in code block
                                    if (a["c"]?[0]?[1]?.AsArray()?.Count == 0)
                                        continue;

                                    // Find the scripts directory
                                    string? mod = FindScriptsDirectory();
                                    if (mod == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to find scripts directory");
                                        Environment.Exit(6);
                                    }

                                    // Extract the code block type (language)
                                    string? typeNode = a["c"]?[0]?[1]?[0]?.ToString();
                                    if (typeNode == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to extract type from code block");
                                        continue;
                                    }
                                    string type = typeNode;

                                    // Build path to the corresponding Python script
                                    string script = Path.Combine(mod, $"CDocs-{type.ToLower()}.py");

                                    if (!File.Exists(script))
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: ERROR: cdocs doesnt understand type {type} - there is no script {script}");
                                        Environment.Exit(5);
                                    }

                                    // Extract the code content
                                    string? codeNode = a["c"]?[1]?.ToString();
                                    if (codeNode == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to extract code from code block");
                                        continue;
                                    }
                                    string code = codeNode;
                                    string html = code;

                                    // Generate unique file names using MD5 hash
                                    MD5 md5 = MD5.Create();
                                    byte[] inputBytes = Encoding.ASCII.GetBytes(html.ToString());
                                    byte[] hash = md5.ComputeHash(inputBytes);
                                    Guid inputGuid = new Guid(hash);

                                    string inputFile = String.Empty;
                                    string outputFile = String.Empty;
                                    bool success = false;
                                    try
                                    {
                                        // Create temporary input file for the Python script
                                        inputFile = Path.Combine(FindContentDirectory(), $"{type.ToLower()}.{Guid.NewGuid()}.tmp");
                                        outputFile = Path.Combine(FindContentDirectory(), Path.GetFileName(inputFile) + ".png");
                                        File.WriteAllText(inputFile, html);

                                        // Execute the Python script to generate image
                                        Process p = new Process();
                                        p.StartInfo.FileName = "python";
                                        p.StartInfo.Arguments = $"{script} {inputFile} {outputFile}";
                                        p.StartInfo.RedirectStandardOutput = true;
                                        p.StartInfo.WindowStyle = ProcessWindowStyle.Normal;

                                        p.Start();
                                        string output = p.StandardOutput.ReadToEnd();
                                        p.WaitForExit();

                                        success = (p.ExitCode == 0);

                                        Console.Error.WriteLine($"CDOCS_FILTER: Redirected python output : {script}");
                                        Console.Error.WriteLine("CDOCS_FILTER: -=-=----------------------------------------");
                                        Console.Error.WriteLine(output);
                                        Console.Error.WriteLine("CDOCS_FILTER: --------------------------------------------");
                                        Console.Error.WriteLine("CDOCS_FILTER: python " + p.StartInfo.Arguments);
                                    }
                                    finally
                                    {
                                        // Clean up temporary input file
                                        if (!String.IsNullOrEmpty(inputFile) && File.Exists(inputFile) && success)
                                        {
                                            Console.Error.WriteLine($"CDOCS_FILTER: DELETING: {inputFile}");
                                            File.Delete(inputFile);
                                        }
                                    }

                                    // Verify the output image was created
                                    if (!File.Exists(outputFile))
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: OUTPUT FILE NOT CREATED: {outputFile}");
                                        Environment.Exit(20);
                                    }
                                    else
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: GOOD: OUTPUT FILE CREATED: {outputFile}");
                                    }

                                    // Generate hash of output file for cache naming
                                    byte[] bits = File.ReadAllBytes(outputFile);
                                    hash = md5.ComputeHash(bits);
                                    Guid outputGuid = new Guid(hash);

                                    // Create cache file names with input and output hashes
                                    string cacheName = type.ToString() + "." + inputGuid.ToString() + "." + outputGuid.ToString();
                                    string cacheImage = Path.Combine(FindContentDirectory(), cacheName + ".png");
                                    string cacheContent = Path.Combine(FindContentDirectory(), cacheName + ".png.cdocs_orig");

                                    // Cache the original JSON for reverse conversion
                                    File.WriteAllText(cacheContent, a.ToJsonString());
                                    File.Move(outputFile, cacheImage, true);

                                    Console.Error.WriteLine($"CDOCS_FILTER: CACHE_IMAGE: {cacheImage}");

                                    // Create relative path for the image reference
                                    string realitivePath = CreeateHackyDirectPath(cacheImage, FindContentDirectory());

                                    Console.Error.WriteLine($"CDOCS_FILTER: IMAGE: {realitivePath},  {FindContentDirectory()}");

                                    // Create the Pandoc Image object structure
                                    // Image structure: ["Image", [attr], [inlines], [url, title]]
                                    object[] imagePieces = new object[3];
                                    PandocObject image = new PandocObject();
                                    image.t = "Image";
                                    image.c = imagePieces;

                                    imagePieces[0] = new object[3] { "", new object[0], new object[0] }; // attributes
                                    imagePieces[1] = new object[0]; // caption (empty)
                                    imagePieces[2] = new object[2] { realitivePath, "" }; // [url, title]

                                    // Wrap the image in a paragraph
                                    PandocObject plain = new PandocObject();
                                    plain.t = "Para";
                                    plain.c = new object[1] { image };

                                    // Replace the original code block with the image paragraph
                                    a.ReplaceWith(plain);
                                }

                                // Reverse direction: Convert Figure back to CodeBlock
                                else if (blah.Equals("Para") && options.Reverse)
                                {
                                    Console.Error.WriteLine("REVERSE MODE AND FOUND IMAGE");
                                    // Find the image path within the figure
                                    string? img = FindImage(a);
                                    if (img == null)
                                        continue;

#if false
                                    try
                                    {
                                        // Navigate the Figure JSON structure to modify Para to Plain
                                        // This fixes formatting issues when converting back
                                        var X = a["c"];
                                        var y = X?[1];
                                        var z = y?[1];
                                        var g = z?[0];
                                        if (g is JsonObject jo)
                                        {
                                             var p = jo.ToArray();
                                            string? heading = p[0].Value?.ToString();

                                            // Convert "Para" elements to "Plain" for proper formatting
                                            if ("Para".Equals(heading))
                                            {
                                                PandocObject newPO = new PandocObject();
                                                newPO.t = "Plain";
                                                newPO.c = p[1].Value;

                                                a["c"]?[1]?[1]?[0]?.ReplaceWith(newPO);
                                            }
                                        }
                                    }
                                    catch (Exception)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: UNABLE To patchup para");
                                        Environment.Exit(4);
                                    }
#endif
                                    // Look up the cached original code block content
                                    if (!m_MappedFiles.TryGetValue(img, out string? localFile) || localFile == null)
                                        continue;

                                    localFile += ".cdocs_orig";

                                    // Restore the original code block from cache
                                    if (File.Exists(localFile))
                                    {
                                        string cache = File.ReadAllText(localFile);
                                        var x = JsonObject.Parse(cache);
                                        a.ReplaceWith(x);
                                    }
                                }
                            }
                        }
                    }
                    catch(Exception e)
                    {
                        Console.Error.WriteLine("CDOCS_FILTER: ERROR (chk debug.json): " + e);
                        Environment.Exit(7);
                    }

                    // Continue recursively processing child nodes
                    Recurse(options, a);
                }
            }

            /// <summary>
            /// Dictionary mapping image paths to their corresponding cache file paths
            /// Used during reverse conversion to locate original code blocks
            /// </summary>
            public Dictionary<string, string> m_MappedFiles = new Dictionary<string, string>();

            /// <summary>
            /// Recursively processes JSON nodes to adjust header levels by the specified increment
            /// </summary>
            /// <param name="options">Command line options</param>
            /// <param name="n">Current JSON node being processed</param>
            /// <param name="inc">Number of levels to increment headers</param>
            private void RecurseTab(Options options, JsonNode? n, int inc)
            {
                if (n == null) return;

                foreach (var a in n.JsonNodeChildren().ToArray())
                {
                    if (null == a)
                        continue;

                    if (a is JsonObject)
                    {
                        var t = a["t"];

                        if (null != t)
                        {
                            var blah = t.GetValue<string>();

                            // Process Header objects to adjust their level
                            if (blah.Equals("Header"))
                            {
                                var c = a["c"];

                                // Header structure: ["Header", level, [attr], [inlines]]
                                // Extract current depth and increment it
                                int depth = Convert.ToInt32(c?[0]?.ToString() ?? "1");
                                c?[0]?.ReplaceWith(depth+inc);
                            }
                        }
                    }
                    // Continue processing recursively (note: calls Recurse, not RecurseTab)
                    Recurse(options, a);
                }
            }

            /// <summary>
            /// Recursively processes JSON nodes to remap image paths during reverse conversion
            /// Maps generated images back to their cache files for code block restoration
            /// </summary>
            /// <param name="options">Command line options</param>
            /// <param name="n">Current JSON node being processed</param>
            private void Recurse_RemapImages(Options options, JsonNode? n)
            {
                Console.Error.WriteLine("REVERSEIMAGE");

                if (n == null) return;

                foreach (var a in n.JsonNodeChildren().ToArray())
                {
                    if (null == a)
                        continue;

                    if (a is JsonObject)
                    {
                        var t = a["t"];

                        if (null != t)
                        {
                            var blah = t.GetValue<string>();

                            // Process Image objects during reverse conversion
                            if (blah.Equals("Image") && options.Reverse)
                            {
                                Console.Error.WriteLine("  *** FOUND IMAGE");

                                var c = a["c"];
                                // Extract image path from Image structure
                                string? img = c?[2]?[0]?.GetValue<string>();
                                if (img == null) continue;

                                FileInfo fi = new FileInfo(img);

                                bool found = false;

                                // Search for matching file in content directory by file size
                                foreach (string file in System.IO.Directory.GetFiles(FindContentDirectory()))
                                {
                                    FileInfo option = new FileInfo(file);
                                    Console.Error.WriteLine($"     ....comparing : {file}");

                                    // Match files by size (simple but effective for cache lookup)
                                    if (fi.Length == option.Length)
                                    {
                                        Console.Error.WriteLine($"     ....hit : {fi.Length}:{option.Length}");

                                        // Create relative path for the matched file
                                        string newImage = Path.GetRelativePath(Environment.CurrentDirectory, option.FullName).Replace("\\", "/");
                                        // Map the new path to the cache file for later lookup
                                        m_MappedFiles[newImage] = option.FullName;
                                        // Update the image path in the JSON
                                        c?[2]?[0]?.ReplaceWith(newImage);
                                        found = true;
                                        break;
                                    }
                                }

                                if (!found)
                                {
                                    Console.Error.WriteLine($"CDOCS_FILTER: ERROR : unable to locate {img}");
                                    Environment.Exit(80);
                                }
                            }
                        }
                    }
                    // Continue processing recursively
                    Recurse(options, a);
                }
            }
            /// <summary>
            /// Main entry point for the CDocs helper functionality
            /// Handles command line parsing, environment variable processing, and JSON manipulation
            /// </summary>
            /// <param name="args">Command line arguments</param>
            /// <returns>Exit code (0 for success, non-zero for error)</returns>
            public int Main(string[] args)
            {
                bool filterMode = false;

                // Check if running as a Pandoc filter (via environment variable)
                if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("CDOCS_FILTER")))
                {
                    filterMode = true;
                    List<string> simulatedArgs = new List<string>();

                    simulatedArgs.Add("--filterMode");

                    // Process environment variables to simulate command line arguments
                    string? reverse = Environment.GetEnvironmentVariable("CDOCS_REVERSE");
                    if (!String.IsNullOrEmpty(reverse))
                    {
                        simulatedArgs.Add("-r");
                    }

                    string? tab = Environment.GetEnvironmentVariable("CDOCS_TAB");
                    if (!String.IsNullOrEmpty(tab))
                    {
                        simulatedArgs.Add("-t");
                        simulatedArgs.Add(tab);
                    }

                    args = simulatedArgs.ToArray();
                }

                // Log all arguments for debugging
                foreach (string arg in args)
                    Console.Error.WriteLine("CDOCS_FILTER: CDocsMarkdownCommentRender ARG: " + arg);

                // Display startup information when not in filter mode
                if(!filterMode)
                {
                    Console.Error.WriteLine("CDOCS_FILTER: ");
                    Console.Error.WriteLine("CDOCS_FILTER: ");
                    Console.Error.WriteLine("CDOCS_FILTER: ");
                    Console.Error.WriteLine("CDOCS_FILTER: CDocsMarkDownCommentRender - args] ---------------------------------");

                    foreach(var arg in args)
                    {
                        Console.Error.Write(arg + " ");
                    }
                    Console.Error.WriteLine();
                }

                int ret = -1;
                // Parse command line arguments and execute main logic
                Parser.Default.ParseArguments<Options>(args)
                    .WithParsed<Options>(o =>
                    {
                        // Display configuration when not in filter mode
                        if(!o.FilterMode)
                        {
                            Console.Error.WriteLine("CDOCS_FILTER: ");
                            Console.Error.WriteLine("CDOCS_FILTER: ");
                            Console.Error.WriteLine("CDOCS_FILTER: ");
                            Console.Error.WriteLine($"CDOCS_FILTER: CDocsMarkdownCommentRender] ---------------------------------");
                            Console.Error.WriteLine($"CDOCS_FILTER:    Input:{o.InputFile}");
                            Console.Error.WriteLine($"CDOCS_FILTER:   Output:{o.OutputFile}");
                            Console.Error.WriteLine($"CDOCS_FILTER:       DB:{FindContentDirectory()}");
                            Console.Error.WriteLine($"CDOCS_FILTER:  Reverse:{o.Reverse}");
                        }

                        // Ensure content directory exists
                        if (!Directory.Exists(FindContentDirectory()))
                        {
                            Directory.CreateDirectory(FindContentDirectory());
                        }

                        string json = "";

                        // Handle input: either from file or stdin (filter mode)
                        if (!filterMode)
                        {
                            // File mode: read from input file
                            if (!File.Exists(o.InputFile))
                            {
                                Console.Error.WriteLine($"CDOCS_FILTER: ERROR: input file [{o.InputFile}] not found");
                                ret = 1;
                            }

                            if(String.IsNullOrEmpty(o.OutputFile))
                            {
                                Console.Error.WriteLine($"CDOCS_FILTER: ERROR: output file not specified but is required");
                                Environment.Exit(43);
                            }

                            if (o.InputFile != null)
                            {
                                json = File.ReadAllText(o.InputFile);

                                FileInfo fi = new FileInfo(o.InputFile);

                                // Change to input file's directory for relative path resolution
                                string? inputFilesDirectory = Path.GetDirectoryName(fi.FullName);
                                if (inputFilesDirectory != null)
                                    Directory.SetCurrentDirectory(inputFilesDirectory);
                            }
                        }
                        else
                        {
                            // Filter mode: read JSON from stdin until empty line
                            string? s = Console.ReadLine();
                            StringBuilder sb = new StringBuilder();
                            sb.AppendLine(s);
                            while (!String.IsNullOrEmpty(s))
                            {
                                s = Console.ReadLine();
                                sb.AppendLine(s);
                            }
                            json = sb.ToString();
                        }

                        // Parse the JSON into a Pandoc AST
                        JsonNode forecastNode = JsonNode.Parse(json)!;

                        // Get the blocks array from the Pandoc document
                        var x = forecastNode!["blocks"];

                        // Process based on operation mode
                        if (0 != o.TabIncrement)
                        {
                            // Tab mode: adjust header levels
                            if (x != null)
                                RecurseTab(o, x, o.TabIncrement);
                        }
                        else
                        {
                            // Standard mode: process code blocks and images
                            if (x != null)
                            {
                                // First pass: remap images for reverse conversion
                                Recurse_RemapImages(o, x);
                                // Second pass: main processing (convert code blocks or restore from cache)
                                Recurse(o, x);
                            }
                        }

                        // Configure JSON serialization options
                        var options = new JsonSerializerOptions
                        {
                            WriteIndented = true,
                            TypeInfoResolver = new DefaultJsonTypeInfoResolver(),
                            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                        };

                        // Output the processed JSON
                        if (!filterMode)
                        {
                            // File mode: write to output file
                            Console.Error.WriteLine($"CDOCS_FILTER: Output: {o.OutputFile}");
                            if (o.OutputFile != null)
                                File.WriteAllText(o.OutputFile, forecastNode!.ToJsonString(options));
                        }
                        else
                        {
                            // Filter mode: write to stdout
                            Console.WriteLine(forecastNode!.ToJsonString(options));
                        }
                        ret = 0;
                    });

                Console.Error.WriteLine($"CDOCS_FILTER: Exiting:{ret}");
                return ret;
            }
        }

        /// <summary>
        /// Application entry point - creates CDocs helper instance and handles top-level exceptions
        /// </summary>
        /// <param name="args">Command line arguments</param>
        /// <returns>Exit code (0 for success, negative for unhandled errors)</returns>
        static int Main(string[] args)
        {
            try
            {
                // Create and run the CDocs helper
                CDocsPandocHelper helper = new CDocsPandocHelper();
                return helper.Main(args);
            }
            catch (Exception e)
            {
                // Log any unhandled exceptions and exit with error code
                Console.Error.WriteLine("CDOCS_FILTER: ERROR: " + e);
                Environment.Exit(-92);
                return -92;
            }
        }
    }
}