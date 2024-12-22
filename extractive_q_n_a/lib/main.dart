import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const ExtractiveQnAApp());
}

class ExtractiveQnAApp extends StatelessWidget {
  const ExtractiveQnAApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Extractive QnA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const QnAPage(),
    );
  }
}

class QnAPage extends StatefulWidget {
  const QnAPage({Key? key}) : super(key: key);

  @override
  State<QnAPage> createState() => _QnAPageState();
}

class _QnAPageState extends State<QnAPage> {
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _questionController = TextEditingController();
  String _answer = "";

  Future<void> fetchAnswer() async {
    final String context = _contextController.text.trim();
    final String question = _questionController.text.trim();

    if (context.isEmpty || question.isEmpty) {
      setState(() {
        _answer = "Please provide both context and question.";
      });
      return;
    }

    final url = Uri.parse('http://127.0.0.1:8000/qna');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'context': context, 'question': question}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _answer = data['answer'] ?? "No answer found.";
        });
      } else {
        setState(() {
          _answer = "Error: ${response.statusCode} - ${response.reasonPhrase}";
        });
      }
    } catch (e) {
      setState(() {
        _answer = "Error: Unable to connect to server.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Extractive QnA")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _contextController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Enter Context",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: "Enter Question",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: fetchAnswer,
              child: const Text("Get Answer"),
            ),
            const SizedBox(height: 20),
            Text(
              _answer,
              style: const TextStyle(fontSize: 18, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }
}
