﻿
using System;
using System.Diagnostics;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;
using CommandLine;

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
            [Option('i', "input", Required = true, HelpText = "Input File")]
            public string InputFile { get; set; }

            [Option('d', "databaseDir", Required = true, HelpText = "Database Directory")]
            public string DBDir { get; set; }

            [Option('o', "output", Required = true, HelpText = "Reference Directory")]
            public string OutputFile { get; set; }

            [Option('r', "reverse", Required = false, Default = false, HelpText = "Reverse Direcion")]
            public bool Reverse { get; set; }

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

        static void Recurse(Options options, JsonNode n)
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

                        if (blah.Equals("CodeBlock") && !options.Reverse)
                        {
                            string type = a["c"][0][1][0].ToString();

                            if (0 != String.Compare(type, "cdocs"))
                                continue;

                            string code = a["c"][1].ToString();

                            string html = "<pre>" + code + "</pre>";
                            string inputFile = "C:\\temp\\cdocs1.html";
                            string outputFile = "C:\\temp\\cdocs1.html.png";

                            File.WriteAllText(inputFile, html);

                            MD5 md5 = MD5.Create();
                            byte[] inputBytes = Encoding.ASCII.GetBytes(html.ToString());
                            byte[] hash = md5.ComputeHash(inputBytes);
                            Guid inputGuid = new Guid(hash);

                            Process p = new Process();
                            p.StartInfo.FileName = "C:\\Program Files\\wkhtmltopdf\\bin\\wkhtmltoimage.exe";
                            p.StartInfo.Arguments = inputFile + " " + outputFile;
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
                            //File.Move(inputFile, cacheContent, true);
                            File.Move(outputFile, cacheImage, true);


                            FileInfo inputFilePath = new FileInfo(Path.GetDirectoryName(options.InputFile));
                            FileInfo outFile = new FileInfo(cacheImage);

                            string realitivePath = outFile.FullName;
                            realitivePath = "." + realitivePath.Substring(inputFilePath.FullName.Length);
                            realitivePath = realitivePath.Replace("\\", "/");

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

                            object [] figurePieces = new object[3];
                            figurePieces[0] = new object[3] { "", new object[0], new object[0] } ;
                            figurePieces[1] = new object[2] { null, new object[1] { captionText } };
                            figurePieces[2] = new object[1] { plain };

                            PandocObject figure = new PandocObject();
                            figure.t = "Figure";
                            figure.c = figurePieces;


                            a.ReplaceWith(figure);
                        }

                        else if (blah.Equals("Figure") && options.Reverse)
                        {
                            string img = a["c"][2][0][1][0][1][2][0].ToString();
                            Console.WriteLine($"Looking for cache entry for {img}");

                            string heading = a["c"][1][1][0][0].ToString();
                            if("Para".Equals(heading))
                            {
                                Console.WriteLine("Fixed up para/plain");
                                a["c"][1][1][0][0].ReplaceWith("Plain");
                            }


                            //
                            // First swap out with a reference image (if we have one)
                            //
                            FileInfo fi = new FileInfo(img);

                            foreach (string file in System.IO.Directory.GetFiles(options.DBDir))
                            {
                                FileInfo option = new FileInfo(file);

                                if (fi.Length == option.Length)
                                {
                                    string newImage = "./" + Path.GetRelativePath(Environment.CurrentDirectory, option.FullName).Replace("\\", "/");
                                    a["c"][2][0][1][0][1][2][0].ReplaceWith(newImage);
                                    Console.WriteLine($"CACHE HIT: {img}-->{newImage}   ");
                                }
                            }

                            string cacheFile = Path.Combine(Path.GetDirectoryName(options.InputFile), img.Replace("/", "\\") + ".cdocs_orig");
                            if(File.Exists(cacheFile))
                            {
                                Console.WriteLine("FIGURE HIT!");
                                string cache = File.ReadAllText(cacheFile);

                                var x = JsonObject.Parse(cache);
                                a.ReplaceWith(x);
                            }

                        }
                    }
                }

                Recurse(options, a);
            }
        }

        static int Main(string[] args)
        {
            Console.Write("ARGS:");
            foreach(string arg in args)
            {
                Console.Write(arg + " ");
            }
            Console.WriteLine("Starting.");
            int ret = -1;
            Parser.Default.ParseArguments<Options>(args)
                .WithParsed<Options>(o =>
                {
                    Console.WriteLine($"CDocsMarkdownCommentRender:");
                    Console.WriteLine($"   Input:{o.InputFile}");
                    Console.WriteLine($"  Output:{o.OutputFile}");
                    Console.WriteLine($"      DB:{o.DBDir}");
                    Console.WriteLine($" Reverse:{o.Reverse}");


                    if(!File.Exists(o.InputFile))
                    {
                        Console.WriteLine($"ERROR: input file not found {o.InputFile}");
                        ret = 1;
                    }
                    string json = File.ReadAllText(o.InputFile);

                    // Create a JsonNode DOM from a JSON string.
                    JsonNode forecastNode = JsonNode.Parse(json)!;

                    var x = forecastNode!["blocks"];

                    Recurse(o, x);

                    // Write JSON from a JsonNode
                    var options = new JsonSerializerOptions
                    {
                        WriteIndented = true,
                        TypeInfoResolver = new DefaultJsonTypeInfoResolver()
                    };

                    File.WriteAllText(o.OutputFile, forecastNode!.ToJsonString(options));
                    ret = 0;
                    //Console.WriteLine($"...to {o.OutputFile}");
                });

            return ret;
        }
    }
}