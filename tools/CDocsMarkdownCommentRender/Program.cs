﻿
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Encodings.Web;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;
using CommandLine;
using static Pandoc.Comment.Render.Program;

namespace Pandoc.Comment.Render
{
    public static class JsonEnumerator
    {
        public static IEnumerable<JsonNode> JsonNodeChildren(this JsonNode node)
        {
            if (node is JsonObject jObject)
            {
                foreach (var me in jObject)
                {
                    yield return me.Value;
                    foreach (var child in me.Value.JsonNodeChildren())
                        yield return child;
                }
            }
            else if (node is JsonArray jArray)
            {
                foreach (var item in jArray)
                {
                    yield return item;
                    foreach (var child in item.JsonNodeChildren())
                        yield return child;
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
            public string InputFile { get; set; }

            [Option('d', "databaseDir", Required = true, HelpText = "Database Directory, envVar=CDOCS_DB")]
            public string DBDir { get; set; }

            [Option('o', "output", Required = false, HelpText = "Output File")]
            public string OutputFile { get; set; }

            [Option('r', "reverse", Required = false, Default = false, HelpText = "Reverse Direcion, envVar=CDOCS_REVERSE")]
            public bool Reverse { get; set; }

            [Option('t', "tab", Required = false, Default=null, HelpText = "Tab header by <n>, envVar=CDOCS_TAB")]
            public int TabIncrement { get; set; }

            [Option('f', "filerMode", Required = false, Default = false, HelpText = "Pandoc Filter Mode, envVar=CDOCS_FILTER")]
            public bool FilterMode { get; set; }
        }


        class PandocObject
        {
            public string t { get; set; }
            public object c { get; set; }

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


            static string CreeateHackyDirectPath(string file, string db)
            {
                string root = Path.GetDirectoryName(db);

                file = file.Substring(root.Length);
                file = file.Replace("\\", "/");
                file = "/data" + file;
                return file;
            }

            static string CreateRealitivePath(string document, string desiredFile)
            {
                document = new FileInfo(document).FullName;
                desiredFile = new FileInfo(desiredFile).FullName;

                Uri path1 = new Uri(document);
                Uri path2 = new Uri(desiredFile);
                Uri diff = path1.MakeRelativeUri(path2);
                string relPath = diff.OriginalString;

                if (!relPath.StartsWith("."))
                {
                    relPath = "./" + relPath;
                }

                /* string realitiveOuputPath = outFile.FullName;
                 realitiveOuputPath = "." + realitiveOuputPath.Substring(inputFilePath.FullName.Length);
                 realitiveOuputPath = realitiveOuputPath.Replace("\\", "/");*/

                return relPath;
            }

            private static Stack<string> SplitDirectory(string temp)
            {
                Stack<string> docStack = new Stack<string>();
                for (; ; )
                {
                    string doc = Path.GetFileName(temp);
                    if (String.IsNullOrEmpty(doc))
                    {
                        docStack.Push(temp);
                        break;
                    }
                    docStack.Push(doc);
                    temp = temp.Substring(0, temp.Length - doc.Length);
                    if (temp.EndsWith(Path.DirectorySeparatorChar))
                        temp = temp.Substring(0, temp.Length - 1);
                }

                return docStack;
            }

            string FindImage(JsonNode n)
            {
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
                                string me = a["c"][2][0].ToString();
                                return me;
                            }
                        }
                    }
                }
                return null;
            }


            void Recurse(Options options, JsonNode n)
            {
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
                                    if (0 == a["c"][0][1].AsArray().Count)
                                        continue;

                                    string type = a["c"][0][1][0].ToString();
                                    string script = $"c:\\Source\\CDocs\\scripts\\CDocs-{type.ToLower()}.ps1";

                                    if(!File.Exists(script))
                                    {
                                        Console.Error.WriteLine($"ERROR: cdocs doesnt understand type {type} - there is no script {script}");
                                        Environment.Exit(5);
                                    }

                                    string code = a["c"][1].ToString();

                                    string html = code;

                                    MD5 md5 = MD5.Create();
                                    byte[] inputBytes = Encoding.ASCII.GetBytes(html.ToString());
                                    byte[] hash = md5.ComputeHash(inputBytes);
                                    Guid inputGuid = new Guid(hash);

                                    string inputFile = Path.Combine(options.DBDir, $"{type.ToLower()}.{Guid.NewGuid()}.tmp");
                                    string outputFile = inputFile + ".png";
                                    File.WriteAllText(inputFile, html);


                                    Process p = new Process();
                                    p.StartInfo.FileName = "pwsh";
                                    p.StartInfo.Arguments = $"{script} {inputFile} {outputFile}";
                                    p.StartInfo.WindowStyle = ProcessWindowStyle.Normal;
                                    p.Start();
                                    p.WaitForExit();

                                    byte[] bits = File.ReadAllBytes(outputFile);
                                    hash = md5.ComputeHash(bits);
                                    Guid outputGuid = new Guid(hash);

                                    string cacheName = inputGuid.ToString() + "." + outputGuid.ToString();
                                    string cacheImage = Path.Combine(options.DBDir, cacheName + ".png");
                                    string cacheContent = Path.Combine(options.DBDir, cacheName + ".png.cdocs_orig");


                                    File.WriteAllText(cacheContent, a.ToJsonString());
                                    File.Move(outputFile, cacheImage, true);

                                    Console.Error.WriteLine($"**NOT DELETING: {inputFile}");
                                    //File.Delete(inputFile);

                                    string realitivePath = CreeateHackyDirectPath(cacheImage, options.DBDir);


                                    //
                                    // Create a caption
                                    //
                                    PandocObject captionBody = new PandocObject();
                                    captionBody.t = "Str";
                                    captionBody.c = "My Caption";

                                    PandocObject captionText = new PandocObject();
                                    captionText.t = "Plain";
                                    captionText.c = new object[] { captionBody };


                                    //
                                    // Create the image
                                    //
                                    object[] imagePieces = new object[3];
                                    PandocObject image = new PandocObject();
                                    image.t = "Image";
                                    image.c = imagePieces;

                                    imagePieces[0] = new object[3] { "", new object[0], new object[0] };
                                    imagePieces[1] = new object[1] { new PandocObject("Str", "Caption") };
                                    imagePieces[2] = new object[2] { realitivePath, "" };

                                    PandocObject plain = new PandocObject();
                                    plain.t = "Plain";
                                    plain.c = new object[1] { image };

                                    object[] figurePieces = new object[3];
                                    figurePieces[0] = new object[3] { "", new object[0], new object[0] };
                                    figurePieces[1] = new object[2] { null, new object[1] { captionText } };
                                    figurePieces[2] = new object[1] { plain };

                                    PandocObject figure = new PandocObject();
                                    figure.t = "Figure";
                                    figure.c = figurePieces;


                                    a.ReplaceWith(figure);
                                }

                                else if (blah.Equals("Figure") && options.Reverse)
                                {
                                    string img = FindImage(a);
                                    try
                                    {
                                        var X = a["c"];
                                        var y = X[1];
                                        var z = y[1];
                                        var g = z[0];
                                        JsonObject jo = (JsonObject)g;

                                        var p = jo.ToArray();
                                        string heading = p[0].Value.ToString();

                                        if ("Para".Equals(heading))
                                        {
                                            PandocObject newPO = new PandocObject();
                                            newPO.t = "Plain";
                                            newPO.c = p[1].Value ;

                                            a["c"][1][1][0].ReplaceWith(newPO);
                                        }
                                    }
                                    catch (Exception)
                                    {
                                        Console.Error.WriteLine("UNABLE To patchup para");
                                        Environment.Exit(4);
                                    }

                                    string localFile;
                                    if (!m_MappedFiles.TryGetValue(img, out localFile))
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
                        Console.Error.WriteLine("ERROR: " + e);
                        Console.Error.WriteLine(n.ToJsonString());

                        Environment.Exit(7);
                    }

                    Recurse(options, a);
                }
            }

            public Dictionary<string, string> m_MappedFiles = new Dictionary<string, string>();

            void RecurseTab(Options options, JsonNode n, int inc)
            {
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

                                int depth = Convert.ToInt32(c[0].ToString());
                                c[0].ReplaceWith(depth+inc);
                            }
                        }
                    }
                    Recurse(options, a);
                }
            }

            void Recurse_RemapImages(Options options, JsonNode n)
            {
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
                                string img = c[2][0].GetValue<string>();

                                FileInfo fi = new FileInfo(img);

                                bool found = false;

                                foreach (string file in System.IO.Directory.GetFiles(options.DBDir))
                                {
                                    FileInfo option = new FileInfo(file);

                                    if (fi.Length == option.Length)
                                    {
                                        string newImage = Path.GetRelativePath(Environment.CurrentDirectory, option.FullName).Replace("\\", "/");
                                        m_MappedFiles[newImage] = option.FullName;
                                        c[2][0].ReplaceWith(newImage);
                                        found = true;
                                        break;
                                    }
                                }

                                if (!found)
                                {
                                    Console.Error.WriteLine($"ERROR : unable to locate {img}");
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

                    simulatedArgs.Add("--filerMode");

                    string reverse = Environment.GetEnvironmentVariable("CDOCS_REVERSE");
                    if (!String.IsNullOrEmpty(reverse))
                    {
                        simulatedArgs.Add("-r");
                    }

                    string db = Environment.GetEnvironmentVariable("CDOCS_DB");
                    if (!String.IsNullOrEmpty(db))
                    {
                        simulatedArgs.Add("-d");
                        simulatedArgs.Add(db);
                    }

                    string tab = Environment.GetEnvironmentVariable("CDOCS_TAB");
                    if (!String.IsNullOrEmpty(db))
                    {
                        simulatedArgs.Add("-t");
                        simulatedArgs.Add(tab);
                    }

                    args = simulatedArgs.ToArray();
                }


                if(!filterMode)
                {
                    Console.Error.WriteLine("");
                    Console.Error.WriteLine("");
                    Console.Error.WriteLine("");
                    Console.Error.WriteLine("CDocsMarkDownCommentRender - args] ---------------------------------");

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

                        if(!o.FilterMode) {
                            Console.Error.WriteLine("");
                            Console.Error.WriteLine("");
                            Console.Error.WriteLine("");
                            Console.Error.WriteLine($"CDocsMarkdownCommentRender] ---------------------------------");
                            Console.Error.WriteLine($"   Input:{o.InputFile}");
                            Console.Error.WriteLine($"  Output:{o.OutputFile}");
                            Console.Error.WriteLine($"      DB:{o.DBDir}");
                            Console.Error.WriteLine($" Reverse:{o.Reverse}");
                        }
                                             
                        if (!Directory.Exists(o.DBDir))
                        {
                            Directory.CreateDirectory(o.DBDir);
                        }

                        string json;

                        if (!filterMode)
                        {
                            
                            if (!File.Exists(o.InputFile))
                            {
                                Console.Error.WriteLine($"ERROR: input file not found {o.InputFile}");
                                ret = 1;
                            }
                            json = File.ReadAllText(o.InputFile);

                            string inputFilesDirectory = Path.GetDirectoryName(o.InputFile);
                            Directory.SetCurrentDirectory(inputFilesDirectory);
                        }
                        else
                        {
                            string s = Console.ReadLine();
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
                            RecurseTab(o, x, o.TabIncrement);
                        }
                        else
                        {
                            Recurse_RemapImages(o, x);
                            Recurse(o, x);
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
                            File.WriteAllText(o.OutputFile, forecastNode!.ToJsonString(options));
                        }
                        else
                        {
                            Console.WriteLine(forecastNode!.ToJsonString(options));
                        }
                        ret = 0;
                    });

                return ret;
            }
        }

        static int Main(string[] args)
        {
            CDocsPandocHelper helper = new CDocsPandocHelper();
            return helper.Main(args);
        }
    }
}