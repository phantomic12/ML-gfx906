using MarkdownTable;

namespace ResultsConverter.Test
{
    [TestClass]
    public sealed class MarkdownTableBuilderExtensionsTest
    {
        private class Row
        {
            public string Name { get; set; } = "";
            public int Num { get; set; }
            public bool Flag { get; set; }
            public double? Opt { get; set; }
            public object Ignored { get; set; } = new object();
            public string Field = "f";
        }

        private static string[] Lines(string table) => table
            .Split(Environment.NewLine)
            .Where(x => x.Length > 0)
            .ToArray();

        [TestMethod]
        public void RenderablePropertiesAndFieldsAreUsedAsColumns()
        {
            var lines = Lines(new[] { new Row { Name = "n1", Num = 3, Flag = true, Opt = 1.5 } }
                .ToMardownTableString());

            CollectionAssert.AreEqual(new[]
            {
                "  Name | Num | Flag | Opt | Field  ",
                " ------|-----|------|-----|------- ",
                "  n1   | 3   | True | 1.5 | f      ",
            }, lines);
        }

        [TestMethod]
        public void NonRenderableMembersAreSkipped()
        {
            var header = Lines(new[] { new Row { Opt = 0 } }.ToMardownTableString())[0];

            Assert.IsFalse(header.Contains(nameof(Row.Ignored)));
        }

        [TestMethod]
        public void EveryRowIsRendered()
        {
            var rows = new[]
            {
                new Row { Name = "a", Opt = 0 },
                new Row { Name = "b", Opt = 0 },
                new Row { Name = "c", Opt = 0 },
            };

            var lines = Lines(rows.ToMardownTableString());

            Assert.AreEqual(rows.Length + 2, lines.Length);
        }

        [TestMethod]
        public void NullValuesAreNotSupported()
        {
            var rows = new[] { new Row { Name = "a", Opt = null } };

            Assert.ThrowsException<NullReferenceException>(() => rows.ToMardownTableString());
        }
    }
}
