import 'dart:io';
import 'package:args/args.dart';
import 'package:lakos/lakos.dart';

enum ExitCode {
  Ok,
  InvalidOption,
  NoRootDirectorySpecified,
  BuildModelFailed,
  WriteToFileFailed,
  DependencyCycleDetected
}

const outputDefault = 'STDOUT';

const usageHeader = '''

Usage: lakos [options] <root-directory>
''';

const usageFooter = '';

void printUsage(ArgParser parser) {
  print(usageHeader);
  print(parser.usage);
  print(usageFooter);
}

void main(List<String> arguments) {
  // Validate args > Create model > compute metrics > output formats > detect cycles
  // SLOC command: cloc --include-lang=Dart --by-file .

  var parser = ArgParser()
    ..addOption('format',
        abbr: 'f',
        help: 'Output format.',
        valueHelp: 'FORMAT',
        allowed: ['dot', 'json'],
        defaultsTo: 'dot')
    ..addOption('output',
        abbr: 'o',
        help: 'Save output to a file instead of printing it.',
        valueHelp: 'FILE',
        defaultsTo: outputDefault)
    ..addFlag('tree',
        help: 'Show directory structure as subgraphs.',
        defaultsTo: true,
        negatable: true)
    ..addFlag('metrics',
        abbr: 'm',
        help: 'Compute and show global metrics.\n(defaults to --no-metrics)',
        defaultsTo: false,
        negatable: true)
    ..addFlag('node-metrics',
        help:
            'Show node metrics. Only works when --metrics is true.\n(defaults to --no-node-metrics)',
        defaultsTo: false,
        negatable: true)
    ..addOption('ignore',
        abbr: 'i',
        help: 'Exclude files and directories with a glob pattern.',
        valueHelp: 'GLOB',
        defaultsTo: '!**')
    ..addFlag('cycles-allowed',
        help:
            'With --no-cycles-allowed lakos runs normally\nbut exits with a non-zero exit code\nif a dependency cycle is detected.\nUseful for CI builds.\n(defaults to --no-cycles-allowed)',
        defaultsTo: false,
        negatable: true)
    ..addFlag('compute-all-cycles',
        defaultsTo: false,
        help:
            'Compute all dependency cycles instead of stopping after the first. Only available if metrics is set and format is json.');

  // Parse args.
  late ArgResults argResults;

  try {
    argResults = parser.parse(arguments);
  } catch (e) {
    print(e);
    printUsage(parser);
    exit(ExitCode.InvalidOption.index);
  }

  if (argResults.rest.length != 1) {
    print('No root directory specified.');
    printUsage(parser);
    exit(ExitCode.NoRootDirectorySpecified.index);
  }

  // Get options.
  var rootDir = Directory(argResults.rest[0]);
  var format = argResults['format'] as String?;
  var output = argResults['output'] as String?;
  var tree = argResults['tree'] as bool;
  var metrics = argResults['metrics'] as bool;
  var nodeMetrics = argResults['node-metrics'] as bool;
  var ignore = argResults['ignore'] as String;
  var cyclesAllowed = argResults['cycles-allowed'] as bool?;
  var computeAllCycles = argResults['compute-all-cycles'] as bool?;

  // Build model.
  late Model model;
  try {
    model = buildModel(rootDir,
        ignoreGlob: ignore,
        showTree: tree,
        showMetrics: metrics,
        showNodeMetrics: nodeMetrics,
        computeAllCycles: computeAllCycles == true);
  } catch (e) {
    print(e);
    exit(ExitCode.BuildModelFailed.index);
  }

  // Write output to STDOUT or a file.
  var contents = '';
  switch (format) {
    case 'dot':
      contents = model.getOutput(OutputFormat.Dot);
      break;
    case 'json':
      contents = model.getOutput(OutputFormat.Json);
      break;
  }

  if (output == outputDefault) {
    print(contents);
  } else {
    try {
      if (!File(output!).parent.existsSync()) {
        File(output).parent.createSync(recursive: true);
      }
      File(output).writeAsStringSync(contents);
    } catch (e) {
      print(e);
      exit(ExitCode.WriteToFileFailed.index);
    }
  }

  // Detect cycles.
  if (!cyclesAllowed! && !model.toDirectedGraph().isAcyclic) {
    exit(ExitCode.DependencyCycleDetected.index);
  }
}
