using MarkdownTable;

namespace ResultsConverter.Test
{
    [TestClass]
    public sealed class MarkdownTableBuilderTest
    {
        private static string[] Lines(MarkdownTableBuilder builder) => builder
            .ToString()
            .Split(Environment.NewLine)
            .Where(x => x.Length > 0)
            .ToArray();

        [TestMethod]
        public void HeaderRowAndSeparatorArePaddedToColumnWidth()
        {
            var builder = new MarkdownTableBuilder()
                .WithHeader("a", "bb")
                .WithRow("x", "yyy");

            CollectionAssert.AreEqual(new[]
            {
                "  a | bb   ",
                " ---|----- ",
                "  x | yyy  ",
            }, Lines(builder));
        }

        [TestMethod]
        public void ColumnWidthGrowsToFitLongestCell()
        {
            var builder = new MarkdownTableBuilder()
                .WithHeader("h")
                .WithRow("longvalue");

            CollectionAssert.AreEqual(new[]
            {
                "  h          ",
                " ----------- ",
                "  longvalue  ",
            }, Lines(builder));
        }

        [TestMethod]
        public void HeaderIsOptional()
        {
            var builder = new MarkdownTableBuilder().WithRow(1, 2);

            CollectionAssert.AreEqual(new[]
            {
                " ---|--- ",
                "  1 | 2  ",
            }, Lines(builder));
        }

        [TestMethod]
        public void ShortRowsArePaddedWithEmptyCells()
        {
            var builder = new MarkdownTableBuilder()
                .WithHeader("h1", "h2", "h3")
                .WithRow("only");

            CollectionAssert.AreEqual(new[]
            {
                "  h1   | h2 | h3  ",
                " ------|----|---- ",
                "  only |    |     ",
            }, Lines(builder));
        }

        [TestMethod]
        public void RowsAreRenderedInInsertionOrder()
        {
            var builder = new MarkdownTableBuilder()
                .WithHeader("v")
                .WithRow("second")
                .WithRow("first");

            var lines = Lines(builder);

            Assert.AreEqual(4, lines.Length);
            Assert.IsTrue(lines[2].Contains("second"));
            Assert.IsTrue(lines[3].Contains("first"));
        }

        [TestMethod]
        public void ClearResetsHeaderAndRows()
        {
            var builder = new MarkdownTableBuilder()
                .WithHeader("a")
                .WithRow("b")
                .Clear()
                .WithHeader("z")
                .WithRow("q");

            CollectionAssert.AreEqual(new[]
            {
                "  z  ",
                " --- ",
                "  q  ",
            }, Lines(builder));
        }

        [TestMethod]
        public void EmptyTableCannotBeRendered()
        {
            var builder = new MarkdownTableBuilder();

            Assert.ThrowsException<InvalidOperationException>(() => builder.ToString());
        }

        [TestMethod]
        public void BuilderMethodsReturnSameInstance()
        {
            var builder = new MarkdownTableBuilder();

            Assert.AreSame(builder, builder.WithHeader("a"));
            Assert.AreSame(builder, builder.WithRow("b"));
            Assert.AreSame(builder, builder.Clear());
        }
    }
}
