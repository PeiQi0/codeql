/**
 * INTERNAL use only. This is an experimental API subject to change without notice.
 *
 * Provides classes and predicates for dealing with flow models specified in CSV format.
 *
 * The CSV specification has the following columns:
 * - Sources:
 *   `namespace; type; subtypes; name; signature; ext; output; kind`
 * - Sinks:
 *   `namespace; type; subtypes; name; signature; ext; input; kind`
 * - Summaries:
 *   `namespace; type; subtypes; name; signature; ext; input; output; kind`
 *
 * The interpretation of a row is similar to API-graphs with a left-to-right
 * reading.
 * 1. The `namespace` column selects a package.
 * 2. The `type` column selects a type within that package.
 * 3. The `subtypes` is a boolean that indicates whether to jump to an
 *    arbitrary subtype of that type.
 * 4. The `name` column optionally selects a specific named member of the type.
 * 5. The `signature` column optionally restricts the named member. If
 *    `signature` is blank then no such filtering is done. The format of the
 *    signature is a comma-separated list of types enclosed in parentheses. The
 *    types can be short names or fully qualified names (mixing these two options
 *    is not allowed within a single signature).
 * 6. The `ext` column specifies additional API-graph-like edges. Currently
 *    there are only two valid values: "" and "Annotated". The empty string has no
 *    effect. "Annotated" applies if `name` and `signature` were left blank and
 *    acts by selecting an element that is annotated by the annotation type
 *    selected by the first 4 columns. This can be another member such as a field
 *    or method, or a parameter.
 * 7. The `input` column specifies how data enters the element selected by the
 *    first 6 columns, and the `output` column specifies how data leaves the
 *    element selected by the first 6 columns. An `input` can be either "",
 *    "Argument[n]", "Argument[n1..n2]", "ReturnValue":
 *    - "": Selects a write to the selected element in case this is a field.
 *    - "Argument[n]": Selects an argument in a call to the selected element.
 *      The arguments are zero-indexed, and `-1` specifies the qualifier.
 *    - "Argument[n1..n2]": Similar to "Argument[n]" but select any argument in
 *      the given range. The range is inclusive at both ends.
 *    - "ReturnValue": Selects a value being returned by the selected element.
 *      This requires that the selected element is a method with a body.
 *
 *    An `output` can be either "", "Argument[n]", "Argument[n1..n2]", "Parameter",
 *    "Parameter[n]", "Parameter[n1..n2]", or "ReturnValue":
 *    - "": Selects a read of a selected field, or a selected parameter.
 *    - "Argument[n]": Selects the post-update value of an argument in a call to the
 *      selected element. That is, the value of the argument after the call returns.
 *      The arguments are zero-indexed, and `-1` specifies the qualifier.
 *    - "Argument[n1..n2]": Similar to "Argument[n]" but select any argument in
 *      the given range. The range is inclusive at both ends.
 *    - "Parameter": Selects the value of a parameter of the selected element.
 *      "Parameter" is also allowed in case the selected element is already a
 *      parameter itself.
 *    - "Parameter[n]": Similar to "Parameter" but restricted to a specific
 *      numbered parameter (zero-indexed, and `-1` specifies the value of `this`).
 *    - "Parameter[n1..n2]": Similar to "Parameter[n]" but selects any parameter
 *      in the given range. The range is inclusive at both ends.
 *    - "ReturnValue": Selects the return value of a call to the selected element.
 * 8. The `kind` column is a tag that can be referenced from QL to determine to
 *    which classes the interpreted elements should be added. For example, for
 *    sources "remote" indicates a default remote flow source, and for summaries
 *    "taint" indicates a default additional taint step and "value" indicates a
 *    globally applicable value-preserving step.
 */

private import go
private import internal.DataFlowPrivate
private import internal.FlowSummaryImpl::Private::External
private import internal.FlowSummaryImplSpecific
private import FlowSummary

/**
 * A module importing the frameworks that provide external flow data,
 * ensuring that they are visible to the taint tracking / data flow library.
 */
private module Frameworks {
  // no frameworks currently modeled
}

private predicate sourceModelCsv(string row) { none() }

private predicate sinkModelCsv(string row) { none() }

private predicate summaryModelCsv(string row) { none() }

/**
 * A unit class for adding additional source model rows.
 *
 * Extend this class to add additional source definitions.
 */
class SourceModelCsv extends Unit {
  /** Holds if `row` specifies a source definition. */
  abstract predicate row(string row);
}

/**
 * A unit class for adding additional sink model rows.
 *
 * Extend this class to add additional sink definitions.
 */
class SinkModelCsv extends Unit {
  /** Holds if `row` specifies a sink definition. */
  abstract predicate row(string row);
}

/**
 * A unit class for adding additional summary model rows.
 *
 * Extend this class to add additional flow summary definitions.
 */
class SummaryModelCsv extends Unit {
  /** Holds if `row` specifies a summary definition. */
  abstract predicate row(string row);
}

private predicate sourceModel(string row) {
  sourceModelCsv(row) or
  any(SourceModelCsv s).row(row)
}

private predicate sinkModel(string row) {
  sinkModelCsv(row) or
  any(SinkModelCsv s).row(row)
}

private predicate summaryModel(string row) {
  summaryModelCsv(row) or
  any(SummaryModelCsv s).row(row)
}

/** Holds if a source model exists for the given parameters. */
predicate sourceModel(
  string namespace, string type, boolean subtypes, string name, string signature, string ext,
  string output, string kind
) {
  exists(string row |
    sourceModel(row) and
    row.splitAt(";", 0) = namespace and
    row.splitAt(";", 1) = type and
    row.splitAt(";", 2) = subtypes.toString() and
    subtypes = [true, false] and
    row.splitAt(";", 3) = name and
    row.splitAt(";", 4) = signature and
    row.splitAt(";", 5) = ext and
    row.splitAt(";", 6) = output and
    row.splitAt(";", 7) = kind
  )
}

/** Holds if a sink model exists for the given parameters. */
predicate sinkModel(
  string namespace, string type, boolean subtypes, string name, string signature, string ext,
  string input, string kind
) {
  exists(string row |
    sinkModel(row) and
    row.splitAt(";", 0) = namespace and
    row.splitAt(";", 1) = type and
    row.splitAt(";", 2) = subtypes.toString() and
    subtypes = [true, false] and
    row.splitAt(";", 3) = name and
    row.splitAt(";", 4) = signature and
    row.splitAt(";", 5) = ext and
    row.splitAt(";", 6) = input and
    row.splitAt(";", 7) = kind
  )
}

/** Holds if a summary model exists for the given parameters. */
predicate summaryModel(
  string namespace, string type, boolean subtypes, string name, string signature, string ext,
  string input, string output, string kind
) {
  summaryModel(namespace, type, subtypes, name, signature, ext, input, output, kind, _)
}

/** Holds if a summary model `row` exists for the given parameters. */
predicate summaryModel(
  string namespace, string type, boolean subtypes, string name, string signature, string ext,
  string input, string output, string kind, string row
) {
  summaryModel(row) and
  row.splitAt(";", 0) = namespace and
  row.splitAt(";", 1) = type and
  row.splitAt(";", 2) = subtypes.toString() and
  subtypes = [true, false] and
  row.splitAt(";", 3) = name and
  row.splitAt(";", 4) = signature and
  row.splitAt(";", 5) = ext and
  row.splitAt(";", 6) = input and
  row.splitAt(";", 7) = output and
  row.splitAt(";", 8) = kind
}

private predicate relevantPackage(string package) {
  sourceModel(package, _, _, _, _, _, _, _) or
  sinkModel(package, _, _, _, _, _, _, _) or
  summaryModel(package, _, _, _, _, _, _, _, _)
}

private predicate packageLink(string shortpkg, string longpkg) {
  relevantPackage(shortpkg) and
  relevantPackage(longpkg) and
  longpkg.prefix(longpkg.indexOf(".")) = shortpkg
}

private predicate canonicalPackage(string package) {
  relevantPackage(package) and not packageLink(_, package)
}

private predicate canonicalPkgLink(string package, string subpkg) {
  canonicalPackage(package) and
  (subpkg = package or packageLink(package, subpkg))
}

/**
 * Holds if CSV framework coverage of `package` is `n` api endpoints of the
 * kind `(kind, part)`.
 */
predicate modelCoverage(string package, int pkgs, string kind, string part, int n) {
  pkgs = strictcount(string subpkg | canonicalPkgLink(package, subpkg)) and
  (
    part = "source" and
    n =
      strictcount(string subpkg, string type, boolean subtypes, string name, string signature,
        string ext, string output |
        canonicalPkgLink(package, subpkg) and
        sourceModel(subpkg, type, subtypes, name, signature, ext, output, kind)
      )
    or
    part = "sink" and
    n =
      strictcount(string subpkg, string type, boolean subtypes, string name, string signature,
        string ext, string input |
        canonicalPkgLink(package, subpkg) and
        sinkModel(subpkg, type, subtypes, name, signature, ext, input, kind)
      )
    or
    part = "summary" and
    n =
      strictcount(string subpkg, string type, boolean subtypes, string name, string signature,
        string ext, string input, string output |
        canonicalPkgLink(package, subpkg) and
        summaryModel(subpkg, type, subtypes, name, signature, ext, input, output, kind)
      )
  )
}

/** Provides a query predicate to check the CSV data for validation errors. */
module CsvValidation {
  /** Holds if some row in a CSV-based flow model appears to contain typos. */
  query predicate invalidModelRow(string msg) {
    exists(string pred, string namespace, string type, string name, string signature, string ext |
      sourceModel(namespace, type, _, name, signature, ext, _, _) and pred = "source"
      or
      sinkModel(namespace, type, _, name, signature, ext, _, _) and pred = "sink"
      or
      summaryModel(namespace, type, _, name, signature, ext, _, _, _) and pred = "summary"
    |
      not namespace.regexpMatch("[a-zA-Z0-9_\\.]+") and
      msg = "Dubious namespace \"" + namespace + "\" in " + pred + " model."
      or
      not type.regexpMatch("[a-zA-Z0-9_\\$<>]+") and
      msg = "Dubious type \"" + type + "\" in " + pred + " model."
      or
      not name.regexpMatch("[a-zA-Z0-9_]*") and
      msg = "Dubious name \"" + name + "\" in " + pred + " model."
      or
      not signature.regexpMatch("|\\([a-zA-Z0-9_\\.\\$<>,\\[\\]]*\\)") and
      msg = "Dubious signature \"" + signature + "\" in " + pred + " model."
      or
      not ext.regexpMatch("|Annotated") and
      msg = "Unrecognized extra API graph element \"" + ext + "\" in " + pred + " model."
    )
    or
    exists(string pred, string input, string part |
      sinkModel(_, _, _, _, _, _, input, _) and pred = "sink"
      or
      summaryModel(_, _, _, _, _, _, input, _, _) and pred = "summary"
    |
      (
        invalidSpecComponent(input, part) and
        not part = "" and
        not (part = "Argument" and pred = "sink") and
        not parseArg(part, _)
        or
        specSplit(input, part, _) and
        parseParam(part, _)
      ) and
      msg = "Unrecognized input specification \"" + part + "\" in " + pred + " model."
    )
    or
    exists(string pred, string output, string part |
      sourceModel(_, _, _, _, _, _, output, _) and pred = "source"
      or
      summaryModel(_, _, _, _, _, _, _, output, _) and pred = "summary"
    |
      invalidSpecComponent(output, part) and
      not part = "" and
      not (part = ["Argument", "Parameter"] and pred = "source") and
      msg = "Unrecognized output specification \"" + part + "\" in " + pred + " model."
    )
    or
    exists(string pred, string row, int expect |
      sourceModel(row) and expect = 8 and pred = "source"
      or
      sinkModel(row) and expect = 8 and pred = "sink"
      or
      summaryModel(row) and expect = 9 and pred = "summary"
    |
      exists(int cols |
        cols = 1 + max(int n | exists(row.splitAt(";", n))) and
        cols != expect and
        msg =
          "Wrong number of columns in " + pred + " model row, expected " + expect + ", got " + cols +
            "."
      )
      or
      exists(string b |
        b = row.splitAt(";", 2) and
        not b = ["true", "false"] and
        msg = "Invalid boolean \"" + b + "\" in " + pred + " model."
      )
    )
  }
}

pragma[nomagic]
private predicate elementSpec(
  string namespace, string type, boolean subtypes, string name, string signature, string ext
) {
  sourceModel(namespace, type, subtypes, name, signature, ext, _, _) or
  sinkModel(namespace, type, subtypes, name, signature, ext, _, _) or
  summaryModel(namespace, type, subtypes, name, signature, ext, _, _, _)
}

private string paramsStringPart(Function f, int i) {
  i = -1 and result = "("
  or
  exists(int n, string p | f.getParameterType(n).toString() = p |
    i = 2 * n and result = p
    or
    i = 2 * n - 1 and result = "," and n != 0
  )
  or
  i = 2 * f.getNumParameter() and result = ")"
}

/**
 * Gets a parenthesized string containing all parameter types of this callable, separated by a comma.
 *
 * Returns the empty string if the callable has no parameters.
 * Parameter types are represented by their type erasure.
 */
string paramsString(Function f) { result = concat(int i | | paramsStringPart(f, i) order by i) }

/** Gets the source/sink/summary element corresponding to the supplied parameters. */
SourceOrSinkElement interpretElement(
  string pkg, string type, boolean subtypes, string name, string signature, string ext
) {
  elementSpec(pkg, type, subtypes, name, signature, ext) and
  // Go does not need to distinguish functions with signature
  signature = "" and
  (
    exists(Field f | f.hasQualifiedName(pkg, type, name) | result.asEntity() = f)
    or
    exists(Method m | m.hasQualifiedName(pkg, type, name) |
      result.asEntity() = m
      or
      subtypes = true and result.asEntity().(Method).implements(m)
    )
    or
    type = "" and
    exists(Entity e | e.hasQualifiedName(pkg, name) | result.asEntity() = e)
  )
}

private predicate parseField(string c, DataFlow::FieldContent f) {
  specSplit(_, c, _) and
  exists(string fieldRegex, string package, string className, string fieldName |
    fieldRegex = "^Field\\[(.*)\\.([^.]+)\\.([^.]+)\\]$" and
    package = c.regexpCapture(fieldRegex, 1) and
    className = c.regexpCapture(fieldRegex, 2) and
    fieldName = c.regexpCapture(fieldRegex, 3) and
    f.getField().hasQualifiedName(package, className, fieldName)
  )
}

/** A string representing a synthetic instance field. */
class SyntheticField extends string {
  SyntheticField() { parseSynthField(_, this) }

  /**
   * Gets the type of this field. The default type is `Object`, but this can be
   * overridden.
   */
  Type getType() { result instanceof EmptyInterfaceType }
}

private predicate parseSynthField(string c, string f) {
  specSplit(_, c, _) and
  c.regexpCapture("SyntheticField\\[([.a-zA-Z0-9]+)\\]", 1) = f
}

/** Holds if the specification component parses as a `Content`. */
predicate parseContent(string component, DataFlow::Content content) {
  parseField(component, content)
  or
  parseSynthField(component, content.(DataFlow::SyntheticFieldContent).getField())
  or
  component = "ArrayElement" and content instanceof DataFlow::ArrayContent
  or
  component = "Element" and content instanceof DataFlow::CollectionContent
  or
  component = "MapKey" and content instanceof DataFlow::MapKeyContent
  or
  component = "MapValue" and content instanceof DataFlow::MapValueContent
}

cached
private module Cached {
  /**
   * Holds if `node` is specified as a source with the given kind in a CSV flow
   * model.
   */
  cached
  predicate sourceNode(DataFlow::Node node, string kind) {
    exists(InterpretNode n | isSourceNode(n, kind) and n.asNode() = node)
  }

  /**
   * Holds if `node` is specified as a sink with the given kind in a CSV flow
   * model.
   */
  cached
  predicate sinkNode(DataFlow::Node node, string kind) {
    exists(InterpretNode n | isSinkNode(n, kind) and n.asNode() = node)
  }
}

import Cached
