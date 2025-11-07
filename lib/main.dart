import 'dart:io';
import 'package:flutter/material.dart';

void main() {
  runApp(const BrightnessApp());
}

class BrightnessApp extends StatelessWidget {
  const BrightnessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const BrightnessHome(),
    );
  }
}

class BrightnessHome extends StatefulWidget {
  const BrightnessHome({super.key});

  @override
  State<BrightnessHome> createState() => _BrightnessHomeState();
}

class _BrightnessHomeState extends State<BrightnessHome> {
  List<int> displays = [];
  Map<int, double> brightness = {};
  bool isLoading = false;
  String output = '';

  @override
  void initState() {
    super.initState();
    _detectDisplays();
  }

  Future<void> _detectMacDisplays() async {
    setState(() => isLoading = true);
    try {
      final result = await Process.run('ddcctl', []);
      var output = result.stdout.toString();
      final lines = output.split('\n');
      final found = <int>[];

      for (final line in lines) {
        if (line.contains('D:') && line.contains('I:')) {
          final numStr = line.split('D:')[1].split(' ')[0];
          if (numStr.isNotEmpty) {
            found.add(int.parse(numStr));
          }
        }
      }
      _updateDisplays(found, 'No monitors detected via ddcctl.');
    } catch (e) {
      _handleError(
        'Error detecting displays: $e. Make sure ddcctl is installed (`brew install ddcctl`).',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Detect all connected monitors using `ddcutil detect`
  Future<void> _detectDisplays() async {
    setState(() => isLoading = true);
    try {
      final result = await Process.run('/usr/bin/ddcutil', ['detect']);
      var output = result.stdout.toString();
      final lines = output.split('\n');
      final found = <int>[];

      for (final line in lines) {
        if (line.trim().startsWith('Display ')) {
          final numStr = line.replaceAll(RegExp(r'[^0-9]'), '');
          if (numStr.isNotEmpty) {
            found.add(int.parse(numStr));
          }
        }
      }

      _updateDisplays(found, 'No monitors detected via ddcutil.');
    } catch (e) {
      _handleError('Error detecting displays: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _updateDisplays(List<int> found, String notFoundMessage) {
    if (found.isNotEmpty) {
      setState(() {
        displays = found;
        for (var d in displays) {
          brightness[d] = 0.5; // default
        }
        output = '';
      });
    } else {
      setState(() {
        displays = [];
        output = notFoundMessage;
      });
    }
  }

  void _handleError(String errorMessage) {
    setState(() {
      displays = [];
      output = errorMessage;
    });
  }

  /// Set brightness for a specific display
  Future<void> _setBrightness(int display, double value) async {
    final int target = (value * 100).toInt();
    setState(() => brightness[display] = value);

    if (Platform.isMacOS) {
      await _runProcess('ddcctl', ['-d', '$display', 'b', '$target'], display);
    } else if (Platform.isLinux) {
      await _runProcess('/usr/bin/ddcutil', [
        'setvcp',
        '10',
        '$target',
        '--display=$display',
      ], display);
    }
  }

  Future<void> _runProcess(
    String executable,
    List<String> arguments,
    int display,
  ) async {
    setState(() => isLoading = true);

    try {
      final result = await Process.run(executable, arguments);
      if (result.exitCode != 0) {
        throw ProcessException(
          executable,
          arguments,
          result.stderr,
          result.exitCode,
        );
      }
      setState(() {
        output = 'Display $display: ${(result.stdout as String).trim()}';
      });
    } catch (e) {
      setState(() {
        output = 'Error on display $display: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshDisplays() {
    if (Platform.isMacOS) {
      return _detectMacDisplays();
    } else {
      return _detectDisplays();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Brightness Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshDisplays,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isLoading && displays.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : displays.isEmpty
            ? Center(
                child: Text(
                  output.isEmpty ? 'No displays detected.' : output,
                  textAlign: TextAlign.center,
                ),
              )
            : ListView(
                children: [
                  const Text(
                    'Adjust Brightness for Each Monitor',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),
                  ...displays.map((d) {
                    return Column(
                      children: [
                        Text(
                          'Monitor $d',
                          style: const TextStyle(fontSize: 18),
                        ),
                        Slider(
                          value: brightness[d] ?? 0.5,
                          min: 0.0,
                          max: 1.0,
                          divisions: 20,
                          label: '${((brightness[d] ?? 0.5) * 100).toInt()}%',
                          onChanged: (v) {
                            setState(() => brightness[d] = v);
                          },
                          onChangeEnd: (v) => _setBrightness(d, v),
                        ),
                        Text(
                          'Brightness: ${((brightness[d] ?? 0.5) * 100).toInt()}%',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Divider(),
                      ],
                    );
                  }),
                  const SizedBox(height: 20),
                  if (isLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    Text(output, textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}
