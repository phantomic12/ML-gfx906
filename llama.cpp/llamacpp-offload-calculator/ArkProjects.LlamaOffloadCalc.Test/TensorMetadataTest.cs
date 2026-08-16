using ArkProjects.LlmCalc;
using GGUFSharp;

namespace ArkProjects.LlamaOffloadCalc.Test
{
    [TestClass]
    public sealed class TensorMetadataTest
    {
        [TestMethod]
        public void BlkIdIsParsedFromBlockTensorName()
        {
            var metadata = new TensorMetadata(new GGUFTensorInfo { Name = "blk.17.ffn_gate.weight", Size = 42 });

            Assert.AreEqual(17, metadata.BlkId);
            Assert.AreEqual("blk.17.ffn_gate.weight", metadata.Name);
            Assert.AreEqual(42L, metadata.Size);
        }

        [TestMethod]
        public void BlkIdIsMinusOneForNonBlockTensorName()
        {
            var metadata = new TensorMetadata(new GGUFTensorInfo { Name = "token_embd.weight", Size = 1 });

            Assert.AreEqual(-1, metadata.BlkId);
        }

        [TestMethod]
        public void SizeIsExposedAsSignedValue()
        {
            var metadata = new TensorMetadata(new GGUFTensorInfo
            {
                Name = "blk.0.attn_q.weight",
                Size = 3UL * 1024 * 1024 * 1024
            });

            Assert.AreEqual(3L * 1024 * 1024 * 1024, metadata.Size);
        }

        [TestMethod]
        public void TensorInfoIsPreserved()
        {
            var info = new GGUFTensorInfo
            {
                Name = "blk.3.attn_k.weight",
                Size = 8,
                TensorType = GGUFTensorType.GGML_TYPE_Q4_K,
                DimensionCount = 2,
                Dimensions = [2, 4]
            };

            var metadata = new TensorMetadata(info);

            Assert.AreSame(info, metadata.TensorInfo);
            Assert.AreEqual(GGUFTensorType.GGML_TYPE_Q4_K, metadata.TensorInfo.TensorType);
        }

        [TestMethod]
        public void NonNumericBlockIndexThrows()
        {
            Assert.ThrowsException<FormatException>(() =>
                new TensorMetadata(new GGUFTensorInfo { Name = "blk.abc.weight", Size = 1 }));
        }
    }
}
