using System.Text.Json;

namespace ResultsConverter.Test
{
    [TestClass]
    public sealed class VllmBenchResultTest
    {
        private const string BenchJson = """
                                        {
                                          "date": "20260101-120000",
                                          "endpoint_type": "openai",
                                          "model_id": "Qwen/Qwen3-8B",
                                          "tokenizer_id": "Qwen/Qwen3-8B",
                                          "num_prompts": 16,
                                          "spec_decode_acceptance_rate": 0.75,
                                          "metadata.rocm_ver": "6.4.0",
                                          "metadata.image": "vllm-gfx906:latest",
                                          "metadata.workload": "pp",
                                          "metadata.about": "recipe",
                                          "max_concurrency": 4,
                                          "duration": 61.5,
                                          "completed": 16,
                                          "total_input_tokens": 1024,
                                          "total_output_tokens": 512,
                                          "output_throughput": 12.5,
                                          "total_token_throughput": 25.5,
                                          "input_lens": [64, 64],
                                          "itls": [[0.1, 0.2]],
                                          "mean_ttft_ms": 123.5
                                        }
                                        """;

        [TestMethod]
        public void SnakeCaseAndDottedJsonNamesAreMapped()
        {
            var result = JsonSerializer.Deserialize<VllmBenchResult>(BenchJson)!;

            Assert.AreEqual("20260101-120000", result.Date);
            Assert.AreEqual("openai", result.EndpointType);
            Assert.AreEqual("Qwen/Qwen3-8B", result.ModelId);
            Assert.AreEqual(16, result.NumPrompts);
            Assert.AreEqual(4, result.MaxConcurrency);
            Assert.AreEqual("6.4.0", result.MetadataRocmVer);
            Assert.AreEqual("vllm-gfx906:latest", result.MetadataImage);
            Assert.AreEqual("pp", result.MetadataWorkload);
            Assert.AreEqual("recipe", result.MetadataAbout);
            Assert.AreEqual(0.75, result.SpecDecodeAcceptanceRate);
            Assert.AreEqual(61.5, result.Duration);
            Assert.AreEqual(1024, result.TotalInputTokens);
            Assert.AreEqual(512, result.TotalOutputTokens);
            Assert.AreEqual(25.5, result.TotalTokenThroughput);
            Assert.AreEqual(12.5, result.OutputThroughput);
            Assert.AreEqual(123.5, result.MeanTtftMs);
            CollectionAssert.AreEqual(new long[] { 64, 64 }, result.InputLens);
            CollectionAssert.AreEqual(new[] { 0.1, 0.2 }, result.Itls[0]);
        }

        [TestMethod]
        public void AbsentOptionalValuesStayNull()
        {
            var result = JsonSerializer.Deserialize<VllmBenchResult>("{}")!;

            Assert.IsNull(result.SpecDecodeAcceptanceRate);
            Assert.IsNull(result.MetadataWorkload);
            Assert.IsNull(result.MetadataAbout);
            Assert.AreEqual(0, result.NumPrompts);
        }

        [TestMethod]
        public void ExplicitJsonNullsAreDeserializedAsNull()
        {
            var result = JsonSerializer
                .Deserialize<VllmBenchResult>("""{"spec_decode_acceptance_rate": null, "metadata.workload": null}""")!;

            Assert.IsNull(result.SpecDecodeAcceptanceRate);
            Assert.IsNull(result.MetadataWorkload);
        }

        [TestMethod]
        public void UnknownJsonPropertiesAreIgnored()
        {
            var result = JsonSerializer
                .Deserialize<VllmBenchResult>("""{"model_id": "m", "brand_new_metric": 1}""")!;

            Assert.AreEqual("m", result.ModelId);
        }
    }
}
