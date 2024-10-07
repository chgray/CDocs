
using System;
using System.Text.Json;
using System.Text.Json.Nodes;
using System.Text.Json.Serialization.Metadata;
using CommandLine;

namespace Pandoc.Image.Merge
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

            [Option('r', "referenceDir", Required = true, HelpText = "Reference Directory")]
            public string ReferenceDir { get; set; }

            [Option('o', "output", Required = true, HelpText = "Reference Directory")]
            public string OutputFile { get; set; }

        }

        static void Recurse(JsonNode n, string refDir)
        {
            foreach (var a in n.JsonNodeChildren().ToArray())
            {
                if (null == a)
                    continue;

                if(a.ToString().Contains("png"))
                   Console.WriteLine(a);


                if (a is JsonObject)
                {
                    var t = a["t"];

                    if (null != t)
                    {
                        var blah = t.GetValue<string>();

                        if (blah.Equals("Image"))
                        {
                            var c = a["c"];
                            string img = c[2][0].GetValue<string>();

                            FileInfo fi = new FileInfo(img);

                            foreach (string file in System.IO.Directory.GetFiles(refDir))
                            {
                                FileInfo option = new FileInfo(file);

                                if (fi.Length == option.Length)
                                {
                                    c[2][0].ReplaceWith("./" + Path.GetRelativePath(Environment.CurrentDirectory, option.FullName).Replace("\\", "/"));
                                    Console.WriteLine("hit");
                                }
                            }
                            //var y = a[0];
                            //Console.WriteLine(t);
                        }
                    }
                }

                Recurse(a, refDir);
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

                    Recurse(x, o.ReferenceDir);

                    // Write JSON from a JsonNode
                    var options = new JsonSerializerOptions
                    {
                        WriteIndented = true,
                        TypeInfoResolver = new DefaultJsonTypeInfoResolver()
                    };

                    File.WriteAllText(o.OutputFile, forecastNode!.ToJsonString(options));
                    Console.WriteLine($"...to {o.OutputFile}");
                    //Console.WriteLine(forecastNode!.ToJsonString(options));
                });
        }
    }
}