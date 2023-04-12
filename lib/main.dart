import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  runApp(MyApp());
}

final player = AudioPlayer();

Future<void> playSound(String assetPath) async {
  await player.setAsset(assetPath);
  await player.play();
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'The Rua',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AnimatedSplashScreen(
        splash: Image.asset('assets/logo.png'),
        nextScreen: MainScreen(),
        splashTransition: SplashTransition.fadeTransition,
        backgroundColor: Color(0xFF42A5F5),
        duration: 3000,
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('The Rua'),
      ),
      body: Center(
        child: Text('Tela inicial'),
      ),
    );
  }
}

class MainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('The Rua'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => StartWorkoutScreen()),
                );
              },
              child: Text('Iniciar treino padrão'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => CustomSettingsScreen()),
                );
              },
              child: Text('Configurações personalizadas'),
            ),
          ],
        ),
      ),
    );
  }
}

class StartWorkoutScreen extends StatefulWidget {
  final int? customWorkoutTime;
  final int? customRestTime;
  final int? customTotalRounds;

  StartWorkoutScreen({
    this.customWorkoutTime,
    this.customRestTime,
    this.customTotalRounds,
  });

  @override
  _StartWorkoutScreenState createState() => _StartWorkoutScreenState();
}

class _StartWorkoutScreenState extends State<StartWorkoutScreen> {
  Timer? _timer;
  bool isPaused = true;
  bool isResting = false;

  int _workoutTime = 180;
  int _restTime = 60;
  int _totalRounds = 20;
  int currentRound = 1;
  int timeLeft = 0;

  int get workoutTime => _workoutTime;
  set workoutTime(int value) {
    _workoutTime = value;
  }

  int get restTime => _restTime;
  set restTime(int value) {
    _restTime = value;
  }

  int get totalRounds => _totalRounds;
  set totalRounds(int value) {
    _totalRounds = value;
  }

  @override
  void initState() {
    super.initState();
    if (widget.customWorkoutTime != null) {
      workoutTime = widget.customWorkoutTime!;
    }
    if (widget.customRestTime != null) {
      restTime = widget.customRestTime!;
    }
    if (widget.customTotalRounds != null) {
      totalRounds = widget.customTotalRounds!;
    }
    timeLeft = workoutTime;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_timer != null) {
      _timer?.cancel();
    }
    if (!isResting) {
      playSound('assets/sounds/round_start.mp3');
    }

    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (timeLeft == 0) {
          if (isResting) {
            if (currentRound < totalRounds) {
              currentRound++;
              timeLeft = workoutTime;
              isResting = false;
            } else {
              playSound('assets/sounds/round_end.mp3');
              timer.cancel();
            }
          } else {
            timeLeft = restTime;
            isResting = true;
          }
        } else {
          timeLeft--;
        }
      });
    });
  }

  void _pauseTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
  }

  void _skipRound() {
    if (currentRound < totalRounds) {
      setState(() {
        currentRound++;
        timeLeft = isResting ? restTime : workoutTime;
      });
    }
  }

  void _previousRound() {
    if (currentRound > 1) {
      setState(() {
        currentRound--;
        timeLeft = isResting ? restTime : workoutTime;
      });
    }
  }

  void _resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }

    setState(() {
      currentRound = 1;
      timeLeft = workoutTime;
      isResting = false;
      isPaused = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar treino'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isResting ? 'Descanso' : 'Treino'),
            Text('Round $currentRound de $totalRounds'),
            Text(
              '${timeLeft ~/ 60}:${(timeLeft % 60).toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.headline4,
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    _previousRound();
                  },
                  icon: Icon(Icons.skip_previous),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      isPaused = !isPaused;
                      if (isPaused) {
                        _pauseTimer();
                      } else {
                        _startTimer();
                      }
                    });
                  },
                  icon: Icon(isPaused ? Icons.play_arrow : Icons.pause),
                ),
                IconButton(
                  onPressed: () {
                    _resetTimer();
                  },
                  icon: Icon(Icons.stop),
                ),
                IconButton(
                  onPressed: () {
                    _skipRound();
                  },
                  icon: Icon(Icons.skip_next),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CustomSettingsScreen extends StatefulWidget {
  @override
  _CustomSettingsScreenState createState() => _CustomSettingsScreenState();
}

class _CustomSettingsScreenState extends State<CustomSettingsScreen> {
  final TextEditingController _workoutNameController = TextEditingController();
  TextEditingController _workoutController = TextEditingController();
  TextEditingController _restController = TextEditingController();
  TextEditingController _roundsController = TextEditingController();

  @override
  void dispose() {
    _workoutController.dispose();
    _restController.dispose();
    _roundsController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    int customWorkoutTime = int.parse(_workoutController.text);
    int customRestTime = int.parse(_restController.text);
    int customTotalRounds = int.parse(_roundsController.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StartWorkoutScreen(
          customWorkoutTime: customWorkoutTime,
          customRestTime: customRestTime,
          customTotalRounds: customTotalRounds,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurações personalizadas'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Intervalo de treino (em segundos):'),
            TextField(
              controller: _workoutController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 16),
            Text('Intervalo de descanso (em segundos):'),
            TextField(
              controller: _restController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 16),
            Text('Número de rounds:'),
            TextField(
              controller: _roundsController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveSettings,
              child: Text('Salvar configurações'),
            ),
            Text('Nome do treino:'),
            TextField(
              controller: _workoutNameController,
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
