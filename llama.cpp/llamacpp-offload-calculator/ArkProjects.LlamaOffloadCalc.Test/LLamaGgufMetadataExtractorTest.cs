using ArkProjects.LlmCalc;

namespace ArkProjects.LlamaOffloadCalc.Test
{
    [TestClass]
    public sealed class LLamaGgufMetadataExtractorTest
    {
        private const string SampleFile = "example.gguf";

        private static readonly string[] SampleTensors = ["tensor1", "tensor2", "tensor3"];

        private string _tempDir = null!;

        [TestInitialize]
        public void CreateTempDir()
        {
            _tempDir = Path.Combine(Path.GetTempPath(), $"gguf-{Guid.NewGuid():N}");
            Directory.CreateDirectory(_tempDir);
        }

        [TestCleanup]
        public void RemoveTempDir()
        {
            if (Directory.Exists(_tempDir))
                Directory.Delete(_tempDir, true);
        }

        [TestMethod]
        public void SingleFileModelIsReadOnce()
        {
            var tensors = new LLamaGgufMetadataExtractor(SampleFile).ExtractMetadata();

            CollectionAssert.AreEqual(SampleTensors, tensors.Select(x => x.Name).ToArray());
            Assert.IsTrue(tensors.All(x => x.BlkId == -1));
        }

        [TestMethod]
        public void SplitModelPartsAreAllRead()
        {
            foreach (var i in new[] { 1, 2 })
                File.Copy(SampleFile, Path.Combine(_tempDir, $"model-{i:D5}-of-00002.gguf"));

            var tensors = new LLamaGgufMetadataExtractor(Path.Combine(_tempDir, "model-00001-of-00002.gguf"))
                .ExtractMetadata();

            CollectionAssert.AreEqual(SampleTensors.Concat(SampleTensors).ToArray(),
                tensors.Select(x => x.Name).ToArray());
        }

        [TestMethod]
        public void SplitModelIsReadFromAnyPartPath()
        {
            foreach (var i in new[] { 1, 2 })
                File.Copy(SampleFile, Path.Combine(_tempDir, $"model-{i:D5}-of-00002.gguf"));

            var tensors = new LLamaGgufMetadataExtractor(Path.Combine(_tempDir, "model-00002-of-00002.gguf"))
                .ExtractMetadata();

            Assert.AreEqual(SampleTensors.Length * 2, tensors.Count);
        }

        [TestMethod]
        public void MissingSplitPartThrows()
        {
            File.Copy(SampleFile, Path.Combine(_tempDir, "model-00001-of-00002.gguf"));

            var extractor = new LLamaGgufMetadataExtractor(Path.Combine(_tempDir, "model-00001-of-00002.gguf"));

            Assert.ThrowsException<FileNotFoundException>(() => extractor.ExtractMetadata());
        }
    }
}
