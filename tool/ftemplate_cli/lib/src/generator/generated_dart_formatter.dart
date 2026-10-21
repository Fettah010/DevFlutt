import 'dart:io';

import 'package:dart_style/dart_style.dart';
import 'package:path/path.dart' as p;
import 'package:pub_semver/pub_semver.dart';
import 'package:yaml/yaml.dart';

/// Formats the generated Dart files.
///
/// The brick stores Dart as text with conditional sections, so the rendered
/// file is not always laid out the way `dart format` would lay it out. Running
/// the canonical formatter over the generated files keeps every generated
/// project format-clean, whatever the brick looks like.
class GeneratedDartFormatter {
  const GeneratedDartFormatter();

  /// Formats every Dart file below [projectDir] in place.
  void format(Directory projectDir) {
    final formatter = DartFormatter(
      languageVersion: _languageVersion(projectDir),
      pageWidth: _pageWidth(projectDir),
    );

    for (final file in projectDir.listSync(recursive: true).whereType<File>()) {
      if (!file.path.endsWith('.dart')) {
        continue;
      }
      final source = file.readAsStringSync();
      final formatted = formatter.format(source, uri: file.uri);
      if (formatted != source) {
        file.writeAsStringSync(formatted);
      }
    }
  }

  /// The Dart language version of the generated project.
  ///
  /// It is the lower bound of the generated SDK constraint, which is the
  /// version `dart format` uses for the generated project.
  Version _languageVersion(Directory projectDir) {
    final environment = _generatedYaml(projectDir, 'pubspec.yaml')?['environment'];
    final sdk = environment is YamlMap ? environment['sdk'] : null;
    if (sdk is! String) {
      return DartFormatter.latestLanguageVersion;
    }
    final minimum = VersionConstraint.parse(sdk);
    if (minimum is! VersionRange || minimum.min == null) {
      return DartFormatter.latestLanguageVersion;
    }
    final version = Version(minimum.min!.major, minimum.min!.minor, 0);
    if (version > DartFormatter.latestLanguageVersion) {
      return DartFormatter.latestLanguageVersion;
    }
    return version;
  }

  /// The page width of the generated project.
  ///
  /// It is read from the generated `analysis_options.yaml` so that the
  /// generator and `dart format` agree.
  int _pageWidth(Directory projectDir) {
    final formatter = _generatedYaml(projectDir, 'analysis_options.yaml')?['formatter'];
    final width = formatter is YamlMap ? formatter['page_width'] : null;
    return width is int ? width : DartFormatter.defaultPageWidth;
  }

  YamlMap? _generatedYaml(Directory projectDir, String name) {
    final file = File(p.join(projectDir.path, name));
    if (!file.existsSync()) {
      return null;
    }
    final decoded = loadYaml(file.readAsStringSync());
    return decoded is YamlMap ? decoded : null;
  }
}
