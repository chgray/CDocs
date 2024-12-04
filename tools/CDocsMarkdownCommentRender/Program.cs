
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

                        if (blah.Equals("CodeBlock"))
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
                            string cacheContent = Path.Combine(options.DBDir, cacheName + ".txt");
                            File.Move(inputFile, cacheContent, true);
                            File.Move(outputFile, cacheImage, true);


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
                            imagePieces[2] = new object[2] { "./orig_media/cdocs.png", "" };

                           
                            PandocObject plain = new PandocObject();
                            plain.t = "Plain";
                            plain.c = image;

                          


                            object [] figurePieces = new object[3];
                            figurePieces[0] = new object[3] { "", new object[0], new object[0] } ;
                            figurePieces[1] = new object[2] { null, new object[1] { captionText } };
                            figurePieces[2] = plain;


                            PandocObject figure = new PandocObject();
                            figure.t = "Figure";
                            figure.c = figurePieces;


                            a.ReplaceWith(figure);
                        }
                    }
                }

                Recurse(options, a);
            }
        }

        static void Main(string[] args)
        {
            Parser.Default.ParseArguments<Options>(args)
                .WithParsed<Options>(o =>
                {
                    Console.WriteLine($"Rewriting {o.InputFile}");
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
                    Console.WriteLine($"...to {o.OutputFile}");
                });
        }
    }
}