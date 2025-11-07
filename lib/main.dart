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

      if (found.isNotEmpty) {
        setState(() {
          displays = found;
          for (var d in displays) {
            brightness[d] = 0.5; // default
          }
        });
      } else {
        setState(() {
          output = 'No monitors detected via ddcutil.';
        });
      }
    } catch (e) {
      setState(() {
        output = 'Error detecting displays: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// Set brightness for a specific display
  Future<void> _setBrightness(int display, double value) async {
    final int target = (value * 100).toInt();
    setState(() {
      isLoading = true;
      brightness[display] = value;
    });

    try {
      final result = await Process.run('/usr/bin/ddcutil', [
        'setvcp',
        '10',
        '$target',
        '--display=$display',
      ]);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitor Brightness Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _detectDisplays,
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
                          onChanged: (v) => _setBrightness(d, v),
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
