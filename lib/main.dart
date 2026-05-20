import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Custom Logo Widget
class GraftCountLogo extends StatelessWidget {
  final double size;

  const GraftCountLogo({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: GraftLogoPainter(), size: Size(size, size));
  }
}

class GraftLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2CCEF0)
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Horizontal line leading into graft
    final basePath = Path()
      ..moveTo(size.width * 0.12, size.height * 0.55)
      ..lineTo(size.width * 0.38, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.70,
        size.width * 0.48,
        size.height * 0.78,
      )
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.68,
        size.width * 0.52,
        size.height * 0.55,
      );
    canvas.drawPath(basePath, paint);

    // Hair strand rising from graft
    final hairPath = Path()
      ..moveTo(size.width * 0.52, size.height * 0.55)
      ..quadraticBezierTo(
        size.width * 0.60,
        size.height * 0.25,
        size.width * 0.56,
        size.height * 0.08,
      );
    canvas.drawPath(hairPath, paint);

    // Bulb outline
    canvas.drawCircle(
      Offset(size.width * 0.48, size.height * 0.78),
      size.width * 0.09,
      paint,
    );

    // Magnifying glass ring
    final glassRadius = size.width * 0.18;
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.42),
      glassRadius,
      paint,
    );

    // Magnifying glass handle
    final handlePath = Path()
      ..moveTo(size.width * 0.90, size.height * 0.55)
      ..lineTo(size.width * 0.98, size.height * 0.70);
    canvas.drawPath(handlePath, paint..strokeWidth = size.width * 0.09);

    // Inner highlight in glass
    canvas.drawLine(
      Offset(size.width * 0.70, size.height * 0.32),
      Offset(size.width * 0.82, size.height * 0.48),
      paint..strokeWidth = size.width * 0.05,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GraftZaehlerApp());
}

class GraftZaehlerApp extends StatefulWidget {
  const GraftZaehlerApp({super.key});

  @override
  State<GraftZaehlerApp> createState() => _GraftZaehlerAppState();
}

class _GraftZaehlerAppState extends State<GraftZaehlerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Force complete rebuild on resume
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Graft Zähler',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1C36),
        primaryColor: const Color(0xFF1C3D6E),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF1C3D6E),
          secondary: Color(0xFF2CCEF0),
          surface: Color(0xFF102745),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F2B4F),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF102745),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0F233D),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2CCEF0), width: 1.3),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.white24, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2CCEF0), width: 1.6),
          ),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 3,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            backgroundColor: const Color(0xFF2CCEF0),
            foregroundColor: const Color(0xFF0B1C36),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
      home: const GraftPage(),
    );
  }
}

class GraftPage extends StatefulWidget {
  const GraftPage({super.key});

  @override
  State<GraftPage> createState() => _GraftPageState();
}

class _GraftPageState extends State<GraftPage> {
  final nameController = TextEditingController();
  final needleController = TextEditingController();
  bool _dataLoaded = false;
  late final Future<pw.ThemeData> _pdfThemeFuture = _loadPdfTheme();

  final List<List<List<TextEditingController>>> grafts =
      List.generate(2, (_) =>
        List.generate(3, (_) =>
          List.generate(6, (_) => TextEditingController())
        )
      );

  final List<List<List<FocusNode>>> focusNodes =
      List.generate(2, (_) =>
        List.generate(3, (_) =>
          List.generate(6, (_) => FocusNode())
        )
      );

  // Schriftgrößen für die Tages-Gesamtzusammenfassung (anpassbar)
  double daySummaryLabelFontSize = 13;
  double daySummaryValueFontSize = 18;

  @override
  void initState() {
    super.initState();
    // Load data asynchronously without blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataAsync();
    });
    
    // Auto-save on text changes
    nameController.addListener(_saveData);
    needleController.addListener(_saveData);
  }

  Future<void> _loadDataAsync() async {
    if (_dataLoaded) return;
    await _loadData();
    if (mounted) {
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    nameController.removeListener(_saveData);
    needleController.removeListener(_saveData);
    nameController.dispose();
    needleController.dispose();
    for (var day in grafts) {
      for (var petri in day) {
        for (var controller in petri) {
          controller.dispose();
        }
      }
    }
    for (var day in focusNodes) {
      for (var petri in day) {
        for (var node in petri) {
          node.dispose();
        }
      }
    }
    super.dispose();
  }

  void _focusNext(int day, int petri, int r) {
    int nd = day;
    int np = petri;
    int nr = r + 1;
    if (nr >= 6) {
      nr = 0;
      np = petri + 1;
      if (np >= 3) {
        np = 0;
        nd = day + 1;
        if (nd >= 2) {
          FocusScope.of(context).unfocus();
          return;
        }
      }
    }
    focusNodes[nd][np][nr].requestFocus();
  }

  int hairMultiplier(int row) => row + 1;

  int totalGrafts() {
    int sum = 0;
    for (var day in grafts) {
      for (var dish in day) {
        for (var c in dish) {
          sum += int.tryParse(c.text) ?? 0;
        }
      }
    }
    return sum;
  }

  int totalHair() {
    int sum = 0;
    for (var d = 0; d < 2; d++) {
      for (var p = 0; p < 3; p++) {
        for (var r = 0; r < 6; r++) {
          int g = int.tryParse(grafts[d][p][r].text) ?? 0;
          sum += g * hairMultiplier(r);
        }
      }
    }
    return sum;
  }

  double ratio() {
    int g = totalGrafts();
    if (g == 0) return 0;
    return totalHair() / g;
  }

  int totalGraftsForDay(int day) {
    int sum = 0;
    for (int p = 0; p < 3; p++) {
      for (int r = 0; r < 6; r++) {
        sum += int.tryParse(grafts[day][p][r].text) ?? 0;
      }
    }
    return sum;
  }

  int totalHairForDay(int day) {
    int sum = 0;
    for (int p = 0; p < 3; p++) {
      for (int r = 0; r < 6; r++) {
        int g = int.tryParse(grafts[day][p][r].text) ?? 0;
        sum += g * hairMultiplier(r);
      }
    }
    return sum;
  }

  double ratioForDay(int day) {
    int g = totalGraftsForDay(day);
    if (g == 0) return 0;
    return totalHairForDay(day) / g;
  }

  int _graftValue(int day, int petri, int row) {
    return int.tryParse(grafts[day][petri][row].text) ?? 0;
  }

  String _graftText(int day, int petri, int row) {
    return grafts[day][petri][row].text.trim();
  }

  int _hairValue(int day, int petri, int row) {
    return _graftValue(day, petri, row) * hairMultiplier(row);
  }

  int _totalGraftsForDish(int day, int petri) {
    int sum = 0;
    for (int row = 0; row < 6; row++) {
      sum += _graftValue(day, petri, row);
    }
    return sum;
  }

  int _totalHairForDish(int day, int petri) {
    int sum = 0;
    for (int row = 0; row < 6; row++) {
      sum += _hairValue(day, petri, row);
    }
    return sum;
  }

  double _ratioForDish(int day, int petri) {
    final totalGrafts = _totalGraftsForDish(day, petri);
    if (totalGrafts == 0) return 0;
    return _totalHairForDish(day, petri) / totalGrafts;
  }

  String _ratioText(int graftCount, double value) {
    return graftCount == 0 ? '-' : value.toStringAsFixed(2);
  }

  String _textOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('name', nameController.text);
    prefs.setString('needle', needleController.text);

    for (int d = 0; d < 2; d++) {
      for (int p = 0; p < 3; p++) {
        for (int r = 0; r < 6; r++) {
          prefs.setString('g_${d}_${p}_$r', grafts[d][p][r].text);
        }
      }
    }
  }

  Future<void> _loadData() async {
    try {
      await Future.delayed(Duration(milliseconds: 100)); // Small delay
      final prefs = await SharedPreferences.getInstance();
      
      if (!mounted) return;
      
      nameController.text = prefs.getString('name') ?? '';
      needleController.text = prefs.getString('needle') ?? '';

      for (int d = 0; d < 2; d++) {
        for (int p = 0; p < 3; p++) {
          for (int r = 0; r < 6; r++) {
            grafts[d][p][r].text = prefs.getString('g_${d}_${p}_$r') ?? '';
          }
        }
      }
    } catch (e) {
      // Silently handle errors - start with empty state
      debugPrint('Error loading data: $e');
    }
  }

  Future<void> _performReset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear controllers in memory
      nameController.clear();
      needleController.clear();
      for (int d = 0; d < 2; d++) {
        for (int p = 0; p < 3; p++) {
          for (int r = 0; r < 6; r++) {
            grafts[d][p][r].text = '';
          }
        }
      }

      // Remove exported files if present
      try {
        final dir = await getApplicationDocumentsDirectory();
        final csv = File('${dir.path}/graft_export.csv');
        final pdf = File('${dir.path}/graft_export.pdf');
        if (await csv.exists()) await csv.delete();
        if (await pdf.exists()) await pdf.delete();
      } catch (_) {}

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alle Daten wurden zurückgesetzt')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Zurücksetzen: $e')),
      );
    }
  }

  void _showResetConfirmation() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Alle Daten löschen?'),
          content: const Text('Möchtest du wirklich alle Daten löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performReset();
              },
              child: const Text(
                'Löschen',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> exportCSV() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/graft_export.csv');

    String csv = 'Tag;Petrischale;Zeile;Grafts;Haare\n';
    for (int d = 0; d < 2; d++) {
      for (int p = 0; p < 3; p++) {
        for (int r = 0; r < 6; r++) {
          int g = int.tryParse(grafts[d][p][r].text) ?? 0;
          csv += '${d + 1};${p + 1};${r + 1};$g;${g * hairMultiplier(r)}\n';
        }
      }
    }

    await file.writeAsString(csv);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('CSV Export gespeichert')),
    );
  }

  Future<void> exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Graft Zähler Bericht',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Name: ${nameController.text}'),
              pw.Text('Entnahmenadel: ${needleController.text}'),
              pw.SizedBox(height: 20),
              pw.Text('Zusammenfassung:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Gesamt Grafts: ${totalGrafts()}'),
              pw.Text('Gesamt Haare: ${totalHair()}'),
              pw.Text('Verhältnis: ${ratio().toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Details:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Tag', 'Petrischale', 'Zeile', 'Grafts', 'Haare'],
                data: _buildTableData(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ],
          );
        },
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/graft_export.pdf');
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PDF Export gespeichert')),
    );
  }

  Future<void> printDocument() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Graft Zähler Bericht',
                  style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Text('Name: ${nameController.text}'),
              pw.Text('Entnahmenadel: ${needleController.text}'),
              pw.SizedBox(height: 20),
              pw.Text('Zusammenfassung:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Gesamt Grafts: ${totalGrafts()}'),
              pw.Text('Gesamt Haare: ${totalHair()}'),
              pw.Text('Verhältnis: ${ratio().toStringAsFixed(2)}'),
              pw.SizedBox(height: 20),
              pw.Text('Details:',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Tag', 'Petrischale', 'Zeile', 'Grafts', 'Haare'],
                data: _buildTableData(),
                cellAlignment: pw.Alignment.centerLeft,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
                cellPadding: const pw.EdgeInsets.all(5),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  List<List<String>> _buildTableData() {
    List<List<String>> data = [];
    for (int d = 0; d < 2; d++) {
      for (int p = 0; p < 3; p++) {
        for (int r = 0; r < 6; r++) {
          int g = int.tryParse(grafts[d][p][r].text) ?? 0;
          if (g > 0) {
            data.add([
              '${d + 1}',
              '${p + 1}',
              '${r + 1}',
              '$g',
              '${g * hairMultiplier(r)}',
            ]);
          }
        }
      }
    }
    return data;
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemLarge(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItemSized(String label, String value, double labelSize, double valueSize) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: labelSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDaySummary(int day) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2B4F), Color(0xFF143863)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2CCEF0), width: 1.2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItemSized('Grafts', '${totalGraftsForDay(day)}', daySummaryLabelFontSize, daySummaryValueFontSize),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.25),
              ),
              _buildSummaryItemSized('Haare', '${totalHairForDay(day)}', daySummaryLabelFontSize, daySummaryValueFontSize),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.25),
              ),
              _buildSummaryItemSized('Verhältnis', ratioForDay(day).toStringAsFixed(2), daySummaryLabelFontSize, daySummaryValueFontSize),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildPetriDish(int day, int petri, double width) {
    // width bereits berücksichtigt: 12px padding left + 12px padding right = 24px
    // Card margin: 4px left + 4px right = 8px
    // Verfügbare Breite für Inhalt: width - 24 - 8 = width - 32
    final contentWidth = width - 32;
    final fieldWidth = (contentWidth - 24) / 2; // 24 = 24px (row number) + 6px spacing
    
    // Berechne Summen für diese Petrischale
    int totalGraftsForDish = 0;
    int totalHairForDish = 0;
    for (int r = 0; r < 6; r++) {
      int g = int.tryParse(grafts[day][petri][r].text) ?? 0;
      totalGraftsForDish += g;
      totalHairForDish += g * hairMultiplier(r);
    }
    double ratioForDish = totalGraftsForDish == 0 ? 0 : totalHairForDish / totalGraftsForDish;
    
    return SizedBox(
      width: width,
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF16325A),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF2CCEF0), width: 1.2),
                ),
                child: Text(
                  'Petrischale ${petri + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 12),
              // Header Row
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF102745),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF2CCEF0).withOpacity(0.3), width: 1),
                ),
                child: Row(
                  children: [
                    SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        'Grafts',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2CCEF0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Haare',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2CCEF0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              ...List.generate(6, (r) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF2CCEF0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${r + 1}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B1C36),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: TextField(
                          focusNode: focusNodes[day][petri][r],
                          controller: grafts[day][petri][r],
                          keyboardType: TextInputType.number,
                          textInputAction: (day == 1 && petri == 2 && r == 5) ? TextInputAction.done : TextInputAction.next,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: const Color(0xFF0F233D),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 12,
                            ),
                            isDense: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF2CCEF0), width: 1.4),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white24, width: 1.2),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Colors.white, width: 1.8),
                            ),
                          ),
                          onSubmitted: (_) async {
                            if (day == 1 && petri == 2 && r == 5) {
                              focusNodes[day][petri][r].unfocus();
                            } else {
                              _focusNext(day, petri, r);
                            }
                            await _saveData();
                            setState(() {});
                          },
                          onChanged: (_) {
                            _saveData();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 36,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F233D),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2CCEF0), width: 1.3),
                          ),
                          child: Text(
                            '${(int.tryParse(grafts[day][petri][r].text) ?? 0) * hairMultiplier(r)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2CCEF0),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
              // Z: Summen Zeile
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16325A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2CCEF0).withOpacity(0.5), width: 1),
                ),
                child: Row(
                  children: [
                    const Text(
                      'Z:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2CCEF0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$totalGraftsForDish',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '$totalHairForDish',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // V: Verhältnis Zeile
              Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF16325A),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2CCEF0).withOpacity(0.5), width: 1),
                ),
                child: Row(
                  children: [
                    const Text(
                      'V:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2CCEF0),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        ratioForDish.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildMainScaffold();
  }

  Scaffold _buildMainScaffold() {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        elevation: 0,
        title: const Text(
          'Graft Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            iconSize: 34,
            splashRadius: 26,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: _showResetConfirmation,
            tooltip: 'Alle Daten zurücksetzen',
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.print),
            iconSize: 34,
            splashRadius: 26,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            onPressed: printDocument,
            tooltip: 'Drucken',
            color: Colors.white,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header Info
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                        ),
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: needleController,
                        decoration: const InputDecoration(
                          labelText: 'Entnahmenadel',
                        ),
                        onChanged: (_) => _saveData(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // All 6 Petri dishes in one horizontal row with Tag headers
                LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth;
                    final petriWidth = (availableWidth / 6.5).clamp(125.0, 230.0);
                    return Center(
                      child: ClipRect(
                        child: InteractiveViewer(
                          boundaryMargin: const EdgeInsets.all(50),
                          minScale: 0.5,
                          maxScale: 3.0,
                          panEnabled: true,
                          scaleEnabled: true,
                          child: IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            // Tag 1 Group
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              Container(
                                width: petriWidth * 3,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2CCEF0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tag 1',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C36),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  buildPetriDish(0, 0, petriWidth),
                                  buildPetriDish(0, 1, petriWidth),
                                  buildPetriDish(0, 2, petriWidth),
                                ],
                              ),
                              SizedBox(
                                width: petriWidth * 3,
                                child: _buildDaySummary(0),
                              ),
                            ],
                          ),
                          const SizedBox(width: 4),
                          // Tag 2 Group
                          Column(                              crossAxisAlignment: CrossAxisAlignment.start,                            children: [
                              Container(
                                width: petriWidth * 3,
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2CCEF0),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Tag 2',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B1C36),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  buildPetriDish(1, 0, petriWidth),
                                  buildPetriDish(1, 1, petriWidth),
                                  buildPetriDish(1, 2, petriWidth),
                                ],
                              ),
                              SizedBox(
                                width: petriWidth * 3,
                                child: _buildDaySummary(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                        ),
                      ),
                        ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Summary
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F2B4F), Color(0xFF143863)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFF2CCEF0), width: 1.2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          const Text(
                            'Gesamtzusammenfassung',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSummaryItemLarge('Grafts', '${totalGrafts()}'),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white.withOpacity(0.25),
                              ),
                              _buildSummaryItemLarge('Haare', '${totalHair()}'),
                              Container(
                                width: 1,
                                height: 50,
                                color: Colors.white.withOpacity(0.25),
                              ),
                              _buildSummaryItemLarge('Verhältnis', ratio().toStringAsFixed(2)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Export Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: ElevatedButton.icon(
                          onPressed: exportCSV,
                          icon: const Icon(Icons.table_chart, size: 22),
                          label: const Text(
                            'CSV Export',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2CCEF0),
                            foregroundColor: const Color(0xFF0B1C36),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: OutlinedButton.icon(
                          onPressed: exportPDF,
                          icon: const Icon(Icons.picture_as_pdf, size: 22, color: Color(0xFF2CCEF0)),
                          label: const Text(
                            'PDF Export',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF2CCEF0)),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF2CCEF0), width: 1.4),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
}
