import 'dart:io';

import 'demo_seed.dart';

void main() {
  final output = File('build/demo_seed.json');
  final contents = '${DemoSeedData.encode()}\n';

  if (output.existsSync()) {
    if (output.readAsStringSync() == contents) {
      stdout
          .writeln('Demo seed already exists and is unchanged: ${output.path}');
      return;
    }
    stderr.writeln(
      'Refusing to replace existing file with different contents: ${output.path}',
    );
    exitCode = 1;
    return;
  }

  output.parent.createSync(recursive: true);
  output.writeAsStringSync(contents, flush: true);
  stdout.writeln('Wrote fictional local-only demo data to ${output.path}');
}
