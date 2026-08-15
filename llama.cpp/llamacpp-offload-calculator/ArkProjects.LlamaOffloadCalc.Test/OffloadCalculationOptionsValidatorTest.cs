using ArkProjects.LlmCalc;
using ArkProjects.LlmCalc.Options;

namespace ArkProjects.LlamaOffloadCalc.Test
{
    [TestClass]
    public sealed class OffloadCalculationOptionsValidatorTest
    {
        private readonly OffloadCalculationOptionsValidator _validator = new();
        private string _ggufPath = null!;

        [TestInitialize]
        public void CreateGgufFile()
        {
            _ggufPath = Path.Combine(Path.GetTempPath(), $"model-{Guid.NewGuid():N}.gguf");
            File.WriteAllText(_ggufPath, "not a real model");
        }

        [TestCleanup]
        public void RemoveGgufFile()
        {
            if (File.Exists(_ggufPath))
                File.Delete(_ggufPath);
        }

        private OffloadCalculationOptions ValidOptions() => new()
        {
            GgufFile = _ggufPath,
            Devices = new Dictionary<string, LLamaDeviceOptions>
            {
                ["ROCm0"] = new() { Type = LLamaDeviceType.GPU, TotalSizeMb = 16384, Id = 0 },
                ["CPU"] = new() { Type = LLamaDeviceType.CPU, TotalSizeMb = 32768, Id = 1 },
            },
            OffloadRules = new Dictionary<string, TensorsOffloadRuleOptions>
            {
                ["ffn_up"] = new() { Regex = @"blk\.\d+\.ffn_up\.weight", Id = 0, Priority = 10 },
            }
        };

        private string[] Errors(OffloadCalculationOptions options)
            => _validator.Validate(options).Errors.Select(x => x.ErrorMessage).ToArray();

        [TestMethod]
        public void ValidOptionsPass()
        {
            Assert.IsTrue(_validator.Validate(ValidOptions()).IsValid);
        }

        [TestMethod]
        public void MissingGgufFileIsRejected()
        {
            var options = ValidOptions();
            options.GgufFile = Path.Combine(Path.GetTempPath(), $"missing-{Guid.NewGuid():N}.gguf");

            CollectionAssert.Contains(Errors(options), "gguf file not exist");
        }

        [TestMethod]
        public void EmptyGgufFilePathIsRejected()
        {
            var options = ValidOptions();
            options.GgufFile = "";

            Assert.IsFalse(_validator.Validate(options).IsValid);
        }

        [TestMethod]
        public void DuplicateDeviceIdsAreRejected()
        {
            var options = ValidOptions();
            options.Devices["CPU"].Id = options.Devices["ROCm0"].Id;

            CollectionAssert.Contains(Errors(options), "Each device must have unique id");
        }

        [TestMethod]
        public void DuplicateOffloadRuleIdsAreRejected()
        {
            var options = ValidOptions();
            options.OffloadRules["ffn_down"] = new TensorsOffloadRuleOptions
            {
                Regex = @"blk\.\d+\.ffn_down\.weight",
                Id = 0
            };

            CollectionAssert.Contains(Errors(options), "Each offload rule must have unique id");
        }

        [TestMethod]
        public void UnknownDeviceTypeIsRejected()
        {
            var options = ValidOptions();
            options.Devices["ROCm1"] = new LLamaDeviceOptions
            {
                Type = LLamaDeviceType.Unknown,
                TotalSizeMb = 8192,
                Id = 2
            };

            CollectionAssert.Contains(Errors(options), "Type must be set for each device");
        }

        [TestMethod]
        public void MissingGpuIsRejected()
        {
            var options = ValidOptions();
            options.Devices.Remove("ROCm0");

            CollectionAssert.Contains(Errors(options), "1 or more GPUs must be defined");
        }

        [TestMethod]
        public void MissingCpuIsRejected()
        {
            var options = ValidOptions();
            options.Devices.Remove("CPU");

            CollectionAssert.Contains(Errors(options), "Single gpu must be defined");
        }

        [TestMethod]
        public void MultipleCpusAreRejected()
        {
            var options = ValidOptions();
            options.Devices["CPU2"] = new LLamaDeviceOptions
            {
                Type = LLamaDeviceType.CPU,
                TotalSizeMb = 32768,
                Id = 2
            };

            CollectionAssert.Contains(Errors(options), "Single gpu must be defined");
        }

        [TestMethod]
        public void MultipleGpusArePermitted()
        {
            var options = ValidOptions();
            options.Devices["ROCm1"] = new LLamaDeviceOptions
            {
                Type = LLamaDeviceType.GPU,
                TotalSizeMb = 16384,
                Id = 2
            };

            Assert.IsTrue(_validator.Validate(options).IsValid);
        }

        [TestMethod]
        public void MissingOffloadRulesAreRejected()
        {
            var options = ValidOptions();
            options.OffloadRules.Clear();

            CollectionAssert.Contains(Errors(options), "1 or more offloading rule must be defined");
        }
    }
}
