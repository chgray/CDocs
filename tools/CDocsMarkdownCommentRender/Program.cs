using System.Diagnostics;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;
using CommandLine;

namespace Pandoc.Comment.Render
{
    public static class JsonEnumerator
    {
        public static IEnumerable<JsonNode> JsonNodeChildren(this JsonNode? node)
        {
            if (node is JsonObject jObject)
            {
                foreach (var me in jObject)
                {
                    if (me.Value != null)
                    {
                        yield return me.Value;
                        foreach (var child in me.Value.JsonNodeChildren())
                            yield return child;
                    }
                }
            }
            else if (node is JsonArray jArray)
            {
                foreach (var item in jArray)
                {
                    if (item != null)
                    {
                        yield return item;
                        foreach (var child in item.JsonNodeChildren())
                            yield return child;
                    }
                }
            }
            else
                yield break;
        }
    }
    internal class Program
    {
        public class Options
        {
            [Option('i', "input", Required = false, HelpText = "Input File")]
            public string? InputFile { get; set; }

            [Option('o', "output", Required = false, HelpText = "Output File")]
            public string? OutputFile { get; set; }

            [Option('r', "reverse", Required = false, Default = false, HelpText = "Reverse Direcion, envVar=CDOCS_REVERSE")]
            public bool Reverse { get; set; }

            [Option('t', "tab", Required = false, Default=null, HelpText = "Tab header by <n>, envVar=CDOCS_TAB")]
            public int TabIncrement { get; set; }

            [Option('f', "filterMode", Required = false, Default = false, HelpText = "Pandoc Filter Mode, envVar=CDOCS_FILTER")]
            public bool FilterMode { get; set; }
        }


        class PandocObject
        {
            public string t { get; set; } = string.Empty;
            public object? c { get; set; }

            public PandocObject() { }
            public PandocObject(string _t, string _c)
            {
                t = _t;
                c = _c;
            }

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


        class CDocsPandocHelper
        {
            static string FindContentDirectory()
            {
                return Path.Combine((FindDBDirectory()), "orig_media");
            }

            static string FindDBDirectory()
            {
                // Find our root
                string? configDir = System.IO.Directory.GetCurrentDirectory();
                for(;;)
                {
                    string root = Path.Combine(configDir, ".CDocs.config");
                    //Console.Error.WriteLine($"CDOCS_FILTER: Looking for config file in {root}");

                    if(File.Exists(root))
                        return configDir;

                    configDir = Path.GetDirectoryName(configDir);
                    if(String.IsNullOrEmpty(configDir))
                    {
                        Console.Error.WriteLine("CDOCS_FILTER: Unable to locate .CDocs.config");
                        Environment.Exit(-122);
                    }
                }
            }
            static string CreeateHackyDirectPath(string file, string db)
            {
                file = new FileInfo(file).FullName;

                // Find our root
                string configDir = FindDBDirectory();

                Console.Error.WriteLine($"CDOCS_FILTER:    CWD : {Directory.GetCurrentDirectory()}");
                Console.Error.WriteLine($"CDOCS_FILTER: CONFIG : {configDir}");
                Console.Error.WriteLine($"CDOCS_FILTER:    FILE: {file}");

                string? dirName = Path.GetDirectoryName(file);
                if (dirName == null)
                    return file; // fallback to original file if can't get directory
                    
                string bits = Path.GetRelativePath(Directory.GetCurrentDirectory(), dirName);
                Console.Error.WriteLine($"CDOCS_FILTER:     REL: {bits}");
                bits += $"{Path.DirectorySeparatorChar}{Path.GetFileName(file)}";
                return bits;
            }
          
            string? FindImage(JsonNode? n)
            {
                if (n == null) return null;
                
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

                            if(0 == blah.CompareTo("Image"))
                            {
                                string? me = a["c"]?[2]?[0]?.ToString();
                                return me;
                            }
                        }
                    }
                }
                return null;
            }
            private string? FindScriptsDirectory()
            {
                string? modulePath = Assembly.GetExecutingAssembly().Location;
                for(; ; )
                {
                    if (string.IsNullOrEmpty(modulePath))
                        return null;
                        
                    string scriptDir = Path.Combine(modulePath, "scripts");
                    if (Directory.Exists(scriptDir))
                        return scriptDir;
                    modulePath = Path.GetDirectoryName(modulePath);
                    if (String.IsNullOrEmpty(modulePath))
                        return null;
                }
            }
            private void Recurse(Options options, JsonNode? n)
            {
                if (n == null) return;
                
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

                                if (blah.Equals("CodeBlock") && !options.Reverse)
                                {
                                    if (a["c"]?[0]?[1]?.AsArray()?.Count == 0)
                                        continue;

                                    string? mod = FindScriptsDirectory();
                                    if (mod == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to find scripts directory");
                                        Environment.Exit(6);
                                    }

                                    string? typeNode = a["c"]?[0]?[1]?[0]?.ToString();
                                    if (typeNode == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to extract type from code block");
                                        continue;
                                    }
                                    string type = typeNode;
                                    string script = Path.Combine(mod, $"CDocs-{type.ToLower()}.py");

                                    if (!File.Exists(script))
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: ERROR: cdocs doesnt understand type {type} - there is no script {script}");
                                        Environment.Exit(5);
                                    }

                                    string? codeNode = a["c"]?[1]?.ToString();
                                    if (codeNode == null)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: ERROR: Unable to extract code from code block");
                                        continue;
                                    }
                                    string code = codeNode;

                                    string html = code;

                                    MD5 md5 = MD5.Create();
                                    byte[] inputBytes = Encoding.ASCII.GetBytes(html.ToString());
                                    byte[] hash = md5.ComputeHash(inputBytes);
                                    Guid inputGuid = new Guid(hash);

                                    string inputFile = String.Empty;
                                    string outputFile = String.Empty;
                                    try
                                    {
                                        inputFile = Path.Combine(FindContentDirectory(), $"{type.ToLower()}.{Guid.NewGuid()}.tmp");
                                        outputFile = Path.Combine(FindContentDirectory(), Path.GetFileName(inputFile) + ".png");
                                        File.WriteAllText(inputFile, html);

                                        Process p = new Process();
                                        p.StartInfo.FileName = "python";
                                        p.StartInfo.Arguments = $"{script} {inputFile} {outputFile}";
                                        p.StartInfo.RedirectStandardOutput = true;
                                        p.StartInfo.WindowStyle = ProcessWindowStyle.Normal;

                                        p.Start();
                                        string output = p.StandardOutput.ReadToEnd();
                                        p.WaitForExit();


                                        Console.Error.WriteLine($"CDOCS_FILTER: Redirected python output : {script}");
                                        Console.Error.WriteLine("CDOCS_FILTER: -=-=----------------------------------------");
                                        Console.Error.WriteLine(output);
                                        Console.Error.WriteLine("CDOCS_FILTER: --------------------------------------------");
                                        Console.Error.WriteLine("CDOCS_FILTER: python " + p.StartInfo.Arguments);
                                    }
                                    finally
                                    {
                                        if (!String.IsNullOrEmpty(inputFile) && File.Exists(inputFile))
                                        {
                                            Console.Error.WriteLine($"CDOCS_FILTER: DELETING: {inputFile}");
                                            File.Delete(inputFile);
                                        }
                                    }

                                    if (!File.Exists(outputFile))
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: OUTPUT FILE NOT CREATED: {outputFile}");
                                        Environment.Exit(20);
                                    }
                                    else
                                    {
                                        Console.Error.WriteLine($"CDOCS_FILTER: GOOD: OUTPUT FILE CREATED: {outputFile}");
                                    }

                                    byte[] bits = File.ReadAllBytes(outputFile);
                                    hash = md5.ComputeHash(bits);
                                    Guid outputGuid = new Guid(hash);

                                    string cacheName = type.ToString() + "." +inputGuid.ToString() + "." + outputGuid.ToString();
                                    string cacheImage = Path.Combine(FindContentDirectory(), cacheName + ".png");
                                    string cacheContent = Path.Combine(FindContentDirectory(), cacheName + ".png.cdocs_orig");


                                    File.WriteAllText(cacheContent, a.ToJsonString());
                                    File.Move(outputFile, cacheImage, true);

                                    Console.Error.WriteLine($"CDOCS_FILTER: DELETING: {inputFile}");
                                    File.Delete(inputFile);

                                     Console.Error.WriteLine($"CDOCS_FILTER: CACHE_IMAGE: {cacheImage}");

                                    string realitivePath = CreeateHackyDirectPath(cacheImage, FindContentDirectory());

                                    Console.Error.WriteLine($"CDOCS_FILTER: IMAGE: {realitivePath},  {FindContentDirectory()}");
                                   

                                    //
                                    // Create the image
                                    //
                                    object[] imagePieces = new object[3];
                                    PandocObject image = new PandocObject();
                                    image.t = "Image";
                                    image.c = imagePieces;

                                    imagePieces[0] = new object[3] { "", new object[0], new object[0] };
                                    imagePieces[1] = new object[0]; //{ "", new object[0], new object[0] };//new PandocObject("Str", "Caption") };
                                    imagePieces[2] = new object[2] { realitivePath, "" };

                                    PandocObject plain = new PandocObject();
                                    plain.t = "Para";
                                    plain.c = new object[1] { image };

                                    a.ReplaceWith(plain);
                                }

                                else if (blah.Equals("Figure") && options.Reverse)
                                {
                                    string? img = FindImage(a);
                                    if (img == null)
                                        continue;
                                        
                                    try
                                    {
                                        var X = a["c"];
                                        var y = X?[1];
                                        var z = y?[1];
                                        var g = z?[0];
                                        if (g is JsonObject jo)
                                        {
                                            var p = jo.ToArray();
                                            string? heading = p[0].Value?.ToString();

                                            if ("Para".Equals(heading))
                                            {
                                                PandocObject newPO = new PandocObject();
                                                newPO.t = "Plain";
                                                newPO.c = p[1].Value ;

                                                a["c"]?[1]?[1]?[0]?.ReplaceWith(newPO);
                                            }
                                        }
                                    }
                                    catch (Exception)
                                    {
                                        Console.Error.WriteLine("CDOCS_FILTER: UNABLE To patchup para");
                                        Environment.Exit(4);
                                    }

                                    if (!m_MappedFiles.TryGetValue(img, out string? localFile) || localFile == null)
                                        continue;


                                    localFile += ".cdocs_orig";

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

                    Recurse(options, a);
                }
            }

            public Dictionary<string, string> m_MappedFiles = new Dictionary<string, string>();

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


                            if (blah.Equals("Header"))
                            {
                                var c = a["c"];

                                int depth = Convert.ToInt32(c?[0]?.ToString() ?? "1");
                                c?[0]?.ReplaceWith(depth+inc);
                            }
                        }
                    }
                    Recurse(options, a);
                }
            }

            private void Recurse_RemapImages(Options options, JsonNode? n)
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


                            if (blah.Equals("Image") && options.Reverse)
                            {
                                var c = a["c"];
                                string? img = c?[2]?[0]?.GetValue<string>();
                                if (img == null) continue;

                                FileInfo fi = new FileInfo(img);

                                bool found = false;

                                foreach (string file in System.IO.Directory.GetFiles(FindContentDirectory()))
                                {
                                    FileInfo option = new FileInfo(file);

                                    if (fi.Length == option.Length)
                                    {
                                        string newImage = Path.GetRelativePath(Environment.CurrentDirectory, option.FullName).Replace("\\", "/");
                                        m_MappedFiles[newImage] = option.FullName;
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
                    Recurse(options, a);
                }
            }
            public int Main(string[] args)
            {
                bool filterMode = false;

                if(!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("CDOCS_FILTER")))
                {
                    filterMode = true;
                    List<string> simulatedArgs = new List<string>();

                    simulatedArgs.Add("--filterMode");

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

                foreach (string arg in args)
                    Console.Error.WriteLine("CDOCS_FILTER: CDocsMarkdownCommentRender ARG: " + arg);

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
                Parser.Default.ParseArguments<Options>(args)
                    .WithParsed<Options>(o =>
                    {
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

                        if (!Directory.Exists(FindContentDirectory()))
                        {
                            Directory.CreateDirectory(FindContentDirectory());
                        }

                        string json = "";

                        if (!filterMode)
                        {
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

                                string? inputFilesDirectory = Path.GetDirectoryName(o.InputFile);
                                if (inputFilesDirectory != null)
                                    Directory.SetCurrentDirectory(inputFilesDirectory);
                            }
                        }
                        else
                        {
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

                        // Create a JsonNode DOM from a JSON string.
                        JsonNode forecastNode = JsonNode.Parse(json)!;

                        var x = forecastNode!["blocks"];

                        if (0 != o.TabIncrement)
                        {
                            if (x != null)
                                RecurseTab(o, x, o.TabIncrement);
                        }
                        else
                        {
                            if (x != null)
                            {
                                Recurse_RemapImages(o, x);
                                Recurse(o, x);
                            }
                        }

                        // Write JSON from a JsonNode
                        var options = new JsonSerializerOptions
                        {
                            WriteIndented = true,
                            TypeInfoResolver = new DefaultJsonTypeInfoResolver(),
                            Encoder = JavaScriptEncoder.UnsafeRelaxedJsonEscaping
                        };


                        if (!filterMode)
                        {
                            Console.Error.WriteLine($"CDOCS_FILTER: Output: {o.OutputFile}");
                            if (o.OutputFile != null)
                                File.WriteAllText(o.OutputFile, forecastNode!.ToJsonString(options));
                        }
                        else
                        {
                            Console.WriteLine(forecastNode!.ToJsonString(options));
                        }
                        ret = 0;
                    });

                Console.Error.WriteLine($"CDOCS_FILTER: Exiting:{ret}");
                return ret;
            }
        }

        static int Main(string[] args)
        {
            try
            {
                CDocsPandocHelper helper = new CDocsPandocHelper();
                return helper.Main(args);
            }
            catch (Exception e)
            {
                Console.Error.WriteLine("CDOCS_FILTER: ERROR: " + e);
                Environment.Exit(-92);
                return -92;
            }
        }
    }
}