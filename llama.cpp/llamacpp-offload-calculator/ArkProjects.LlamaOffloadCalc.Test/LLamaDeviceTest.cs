using ArkProjects.LlmCalc;
using GGUFSharp;

namespace ArkProjects.LlamaOffloadCalc.Test
{
    [TestClass]
    public sealed class LLamaDeviceTest
    {
        private static TensorMetadata Tensor(string name, ulong size)
            => new TensorMetadata(new GGUFTensorInfo { Name = name, Size = size });

        [TestMethod]
        public void UsedSpaceIsReservedMemoryWhenNoTensorsAssigned()
        {
            var device = new LLamaDevice
            {
                Type = LLamaDeviceType.GPU,
                Name = "ROCm0",
                TotalSize = 1000,
                ReservedMemory = 100
            };

            Assert.AreEqual(100, device.GetUsedSpace());
            Assert.AreEqual(900, device.GetFreeSpace());
        }

        [TestMethod]
        public void UsedSpaceIncludesReservedMemoryAndTensors()
        {
            var device = new LLamaDevice
            {
                Type = LLamaDeviceType.GPU,
                Name = "ROCm0",
                TotalSize = 1000,
                ReservedMemory = 100,
                Tensors = [Tensor("blk.0.attn.weight", 300), Tensor("blk.1.attn.weight", 200)]
            };

            Assert.AreEqual(600, device.GetUsedSpace());
            Assert.AreEqual(400, device.GetFreeSpace());
        }

        [TestMethod]
        public void FreeSpaceIsNegativeWhenDeviceIsOversubscribed()
        {
            var device = new LLamaDevice
            {
                Type = LLamaDeviceType.GPU,
                Name = "ROCm0",
                TotalSize = 500,
                Tensors = [Tensor("blk.0.attn.weight", 600)]
            };

            Assert.AreEqual(-100, device.GetFreeSpace());
        }

        [TestMethod]
        public void DefaultsAreEmpty()
        {
            var device = new LLamaDevice
            {
                Type = LLamaDeviceType.CPU,
                Name = "CPU",
                TotalSize = 0
            };

            Assert.AreEqual("", device.PciBus);
            Assert.AreEqual(0, device.ReservedMemory);
            Assert.AreEqual(0d, device.LayersPortion);
            Assert.AreEqual(0, device.Tensors.Count);
            Assert.AreEqual(0, device.Layers.Count);
        }
    }
}
