using ArkProjects.LlmCalc;

namespace ArkProjects.LlamaOffloadCalc.Test
{
    [TestClass]
    public sealed class LLamaLogsParserTest
    {
        private string _logPath = null!;

        [TestInitialize]
        public void CreateLogFile()
        {
            _logPath = Path.Combine(Path.GetTempPath(), $"llama-log-{Guid.NewGuid():N}.txt");
        }

        [TestCleanup]
        public void RemoveLogFile()
        {
            if (File.Exists(_logPath))
                File.Delete(_logPath);
        }

        private void WriteLog(params string[] lines) => File.WriteAllLines(_logPath, lines);

        [TestMethod]
        public void ExtractAssignedLayersGroupsLayersByDevice()
        {
            WriteLog(
                "llama_model_loader: loaded meta data",
                "load_tensors: layer   0 assigned to device ROCm0, is_swa = 0",
                "load_tensors: layer   1 assigned to device ROCm0, is_swa = 0",
                "load_tensors: layer   2 assigned to device CPU, is_swa = 0",
                "load_tensors: offloading 2 repeating layers to GPU");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedLayers();

            Assert.AreEqual(2, result.Count);
            CollectionAssert.AreEqual(new List<int> { 0, 1 }, result["ROCm0"]);
            CollectionAssert.AreEqual(new List<int> { 2 }, result["CPU"]);
        }

        [TestMethod]
        public void ExtractAssignedLayersStopsAfterFirstBlockOfMatches()
        {
            WriteLog(
                "load_tensors: layer   0 assigned to device ROCm0, is_swa = 0",
                "some unrelated line",
                "load_tensors: layer   1 assigned to device ROCm1, is_swa = 0");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedLayers();

            Assert.AreEqual(1, result.Count);
            CollectionAssert.AreEqual(new List<int> { 0 }, result["ROCm0"]);
        }

        [TestMethod]
        public void ExtractAssignedLayersReturnsEmptyWhenNothingMatches()
        {
            WriteLog("load_tensors: nothing to see here", "print_info: file format = GGUF V3");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedLayers();

            Assert.AreEqual(0, result.Count);
        }

        [TestMethod]
        public void ExtractAssignedTensorsGroupsTensorsByDevice()
        {
            WriteLog(
                "llama_model_loader: loaded meta data",
                "tensor blk.0.ffn_up.weight (f16) buffer type overridden to CPU",
                "tensor blk.1.ffn_up.weight (f16) buffer type overridden to CPU",
                "tensor blk.2.ffn_up.weight (f16) buffer type overridden to ROCm0",
                "load_tensors: offloading output layer to GPU");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedTensors();

            Assert.AreEqual(2, result.Count);
            CollectionAssert.AreEqual(new List<string> { "blk.0.ffn_up.weight", "blk.1.ffn_up.weight" },
                result["CPU"]);
            CollectionAssert.AreEqual(new List<string> { "blk.2.ffn_up.weight" }, result["ROCm0"]);
        }

        [TestMethod]
        public void ExtractAssignedTensorsStopsAfterFirstBlockOfMatches()
        {
            WriteLog(
                "tensor blk.0.ffn_up.weight (f16) buffer type overridden to CPU",
                "some unrelated line",
                "tensor blk.1.ffn_up.weight (f16) buffer type overridden to CPU");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedTensors();

            CollectionAssert.AreEqual(new List<string> { "blk.0.ffn_up.weight" }, result["CPU"]);
        }

        [TestMethod]
        public void ExtractAssignedTensorsReturnsEmptyWhenNothingMatches()
        {
            WriteLog("tensor blk.0.ffn_up.weight moved somewhere else");

            var result = new LLamaLogsParser(_logPath).ExtractAssignedTensors();

            Assert.AreEqual(0, result.Count);
        }
    }
}
