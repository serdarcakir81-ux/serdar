import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const TrigoRunApp());
}

class TrigoRunApp extends StatelessWidget {
  const TrigoRunApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trigo-Run',
      theme: ThemeData.dark(),
      home: const GameScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  int score = 0;
  int highScore = 180; // İlk rekorunuzu hafızaya sabitledik!
  bool isGameOver = false;

  String leftDoorText = "";
  String rightDoorText = "";
  int correctDoor = 0;

  double characterX = 0;
  double doorsY = -1.0;

  double baseSpeed = 0.02;
  double currentSpeed = 0.02;

  Timer? gameTimer;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    generateDynamicQuestion();
    startGameLoop();
  }

  void startGameLoop() {
    gameTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        doorsY += currentSpeed;

        if (doorsY >= 0.75 && doorsY <= 0.85) {
          checkCollision();
        }

        if (doorsY > 1.1) {
          doorsY = -1.0;
          generateDynamicQuestion();
        }
      });
    });
  }

  void generateDynamicQuestion() {
    currentSpeed = baseSpeed + (score * 0.0001);
    if (currentSpeed > 0.055) currentSpeed = 0.055;

    int levelType = random.nextInt(5); // 5 farklı ileri düzey soru tipi

    if (levelType == 0) {
      // 1. Bölge Sinüs Karşılaştırması
      int a = random.nextInt(70) + 15;
      int b = random.nextInt(70) + 15;
      while (a == b) {
        b = random.nextInt(70) + 15;
      }
      leftDoorText = "sin $a°";
      rightDoorText = "sin $b°";
      correctDoor = (a > b) ? 0 : 1;
    } else if (levelType == 1) {
      // Sinüs vs Kosinüs Karışık
      int a = random.nextInt(60) + 15;
      int b = random.nextInt(60) + 15;
      int equivalentSin = 90 - b;
      while (a == equivalentSin) {
        b = random.nextInt(60) + 15;
        equivalentSin = 90 - b;
      }
      leftDoorText = "sin $a°";
      rightDoorText = "cos $b°";
      correctDoor = (a > equivalentSin) ? 0 : 1;
    } else if (levelType == 2) {
      // Temel Radyan Karşılaştırması
      List<Map<String, dynamic>> radyanlar = [
        {"text": "π/2", "val": 1.0},
        {"text": "π/3", "val": 0.86},
        {"text": "π/4", "val": 0.70},
        {"text": "π/6", "val": 0.50},
      ];
      int idx1 = random.nextInt(radyanlar.length);
      int idx2 = random.nextInt(radyanlar.length);
      while (idx1 == idx2) {
        idx2 = random.nextInt(radyanlar.length);
      }
      leftDoorText = "sin(${radyanlar[idx1]['text']})";
      rightDoorText = "sin(${radyanlar[idx2]['text']})";
      correctDoor = (radyanlar[idx1]['val'] > radyanlar[idx2]['val']) ? 0 : 1;
    } else if (levelType == 3) {
      // 🎯 Yeni Müfredat: Bölge ve İşaret Tuzağı (Pozitif vs Negatif Bölgeler)
      List<Map<String, dynamic>> pozitifler = [
        {"text": "sin 100°", "val": 0.98},
        {"text": "sin 40°", "val": 0.64},
        {"text": "cos 310°", "val": 0.64},
        {"text": "cos 20°", "val": 0.93},
      ];
      List<Map<String, dynamic>> negatifler = [
        {"text": "sin 200°", "val": -0.34},
        {"text": "cos 120°", "val": -0.50},
        {"text": "sin 330°", "val": -0.50},
        {"text": "cos 250°", "val": -0.34},
      ];
      var poz = pozitifler[random.nextInt(pozitifler.length)];
      var neg = negatifler[random.nextInt(negatifler.length)];

      if (random.nextBool()) {
        leftDoorText = poz["text"];
        rightDoorText = neg["text"];
        correctDoor = 0; // Pozitif olan her zaman büyüktür
      } else {
        leftDoorText = neg["text"];
        rightDoorText = poz["text"];
        correctDoor = 1;
      }
    } else {
      // Tanjant Tuzağı (tan 45 = 1, sinüs asla 1'i geçemez kıyaslaması)
      int a = random.nextInt(40) + 50; // 50 ile 90 arası tanjant her zaman > 1
      int b = random.nextInt(89) + 1;
      leftDoorText = "tan $a°";
      rightDoorText = "sin $b°";
      correctDoor = 0; // tan > 1 olduğu için her zaman sol büyük
    }
  }

  void checkCollision() {
    if ((characterX < 0 && correctDoor == 0) ||
        (characterX > 0 && correctDoor == 1)) {
      score += 10;
      doorsY = 1.2;
    } else {
      gameTimer?.cancel();
      setState(() {
        if (score > highScore) {
          highScore = score;
        }
        isGameOver = true;
      });
    }
  }

  void moveLeft() {
    setState(() {
      characterX = -0.5;
    });
  }

  void moveRight() {
    setState(() {
      characterX = 0.5;
    });
  }

  void restartGame() {
    setState(() {
      score = 0;
      currentSpeed = baseSpeed;
      isGameOver = false;
      characterX = 0;
      doorsY = -1.0;
    });
    generateDynamicQuestion();
    startGameLoop();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isGameOver ? buildGameOverScreen() : buildGamePlayScreen(),
    );
  }

  Widget buildGamePlayScreen() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black87, Color(0xFF1A237E)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        // Skor ve Rekor Alanı
        Positioned(
          top: 40,
          left: 20,
          right: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SKOR: $score',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              Text(
                'REKOR: $highScore',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.tealAccent,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 0),
          alignment: Alignment(0, doorsY),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [buildDoor(leftDoorText), buildDoor(rightDoorText)],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          alignment: Alignment(characterX, 0.75),
          child: Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.bolt, size: 45, color: Colors.black),
          ),
        ),
        Positioned(
          bottom: 50,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: moveLeft,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
              InkWell(
                onTap: moveRight,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward,
                    size: 35,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget buildDoor(String text) {
    return Container(
      width: 155,
      height: 80,
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.cyanAccent, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget buildGameOverScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, size: 90, color: Colors.amber),
          const SizedBox(height: 20),
          const Text(
            'OYUN BİTTİ',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.orangeAccent,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            'Bu Eldeki Skorun: $score',
            style: const TextStyle(fontSize: 24, color: Colors.white70),
          ),
          Text(
            'En Yüksek Skorun: $highScore',
            style: const TextStyle(
              fontSize: 22,
              color: Colors.tealAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: restartGame,
            icon: const Icon(Icons.play_arrow, size: 28),
            label: const Text('Tekrar Dene', style: TextStyle(fontSize: 22)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
