import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class SavedMessage {
  final String text;

  SavedMessage({required this.text});
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Emo',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xff121212),
      ),
      home: const MyHomePage(title: 'Emo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _textEditingController = TextEditingController();
  List<Message> messages = [];
  bool isLoading = false;
  String respoo="";
  String respo = "hi"; // Initialize with the default message
  final String apiKey =
      'AIzaSyA1OTGTtMrXuDT_wzPm3pdh3bl5LkOkb0k'; // Replace with your actual API key
  final String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta2/models/text-bison-001:generateText';

  ScrollController _scrollController = ScrollController();

  void addMessage(String text, bool isUser) {
    setState(() {
      messages.add(Message(text: text, isUser: isUser));
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendRequestAndReceiveResponse() async {
    final String inputText = _textEditingController.text;
    String promptText =
        "Give a brief uplifting and caring reply that sounds like emotional support from a friend for the following text message (use appropriate emojies too): '$inputText', in the context of my previous input: '$respo', and your previous response: '$respoo'";
    final Map<String, dynamic> requestBody = {
      "prompt": {"text": promptText},
      "temperature": 0.9,
      "candidateCount": 1
    };

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        List<dynamic> candidates = responseData['candidates'];

        if (candidates.isNotEmpty) {
          String completionText = candidates[0]['output'];
          addMessage(inputText, true);
          addMessage(completionText, false);
          _textEditingController.clear();
          respo = inputText;
          respoo =completionText;

          // Save the response message to local storage
          saveMessage(completionText);
        }
      } else {
        addMessage('Failed to fetch completion: ${response.statusCode}', false);
      }
    } catch (error) {
      addMessage('Error: $error', false);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void saveMessage(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedMessages = prefs.getStringList('saved_messages') ?? [];
    savedMessages.add(text);
    await prefs.setStringList('saved_messages', savedMessages);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff121212),
        title: Text(
          widget.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 36,
            fontWeight: FontWeight.w900,
            color: Colors.grey[300],
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                return MessageBubble(
                  text: message.text,
                  isUser: message.isUser,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: TextField(
                      controller: _textEditingController,
                      onSubmitted: (_) {
                        sendRequestAndReceiveResponse();
                      },
                      onChanged: (value) {
                        setState(() {
                          // Handle user input change if needed
                        });
                      },
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      decoration: InputDecoration(
                        hintText: 'How are you feeling now ?...',
                        filled: true,
                        fillColor: Colors.grey[800],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(50.0),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8.0,
                          horizontal: 20.0,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    sendRequestAndReceiveResponse();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1c1b1f),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                      : Icon(
                    Icons.send,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      drawer: MyDrawer(),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xff432e81) : const Color(0xff1c1b1f),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: isUser ? Colors.white : Colors.grey[300],
          ),
        ),
      ),
    );
  }
}

class MyDrawer extends StatefulWidget {
  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  List<SavedMessage> savedMessages = [];

  void loadSavedMessages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedMessagesText = prefs.getStringList('saved_messages') ?? [];
    setState(() {
      savedMessages = savedMessagesText.map((text) => SavedMessage(text: text)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    loadSavedMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: const Color(0xff121212),
            ),
            child: Text(
              'Saved Messages',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
          for (var message in savedMessages)
            ListTile(
              title: Text(message.text),
              onTap: () {
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
}
