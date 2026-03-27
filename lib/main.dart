import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Tempo',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool isLoading = true;
  double? temperatura;
  double? vento;
  int? weatherCode;
  String mensagem = '';

  @override
  void initState() {
    super.initState();
    buscarClima();
  }

  Future<void> buscarClima() async {
    setState(() {
      isLoading = true;
    });

    try {
      Position position = await _obterLocalizacao();

      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,weather_code,wind_speed_10m'
        '&timezone=auto',
      );

      final response = await http.get(url);
      final data = jsonDecode(response.body);

      final current = data['current'];

      setState(() {
        temperatura = (current['temperature_2m'] as num).toDouble();
        vento = (current['wind_speed_10m'] as num).toDouble();
        weatherCode = current['weather_code'];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        mensagem = 'Erro ao carregar clima';
        isLoading = false;
      });
    }
  }

  Future<Position> _obterLocalizacao() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Ative o GPS');
    }

    permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return await Geolocator.getCurrentPosition();
  }

  String traduzirClima(int? code) {
    switch (code) {
      case 0:
        return 'Céu limpo';
      case 1:
      case 2:
      case 3:
        return 'Parcialmente nublado';
      case 61:
      case 63:
      case 65:
        return 'Chuva';
      case 95:
        return 'Tempestade';
      default:
        return 'Clima';
    }
  }

  IconData iconeClima(int? code) {
    if (code == 0) return Icons.wb_sunny;
    if (code == 1 || code == 2 || code == 3) return Icons.cloud;
    if (code == 61 || code == 63 || code == 65) return Icons.grain;
    if (code == 95) return Icons.thunderstorm;
    return Icons.cloud_queue;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF2193b0), Color(0xFF6dd5ed)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        iconeClima(weatherCode),
                        size: 100,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '${temperatura?.toStringAsFixed(1) ?? '--'} °C',
                        style: const TextStyle(
                          fontSize: 48,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        traduzirClima(weatherCode),
                        style: const TextStyle(
                          fontSize: 22,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Vento: ${vento?.toStringAsFixed(1) ?? '--'} km/h',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: buscarClima,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 12),
                        ),
                        child: const Text('Atualizar'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        mensagem,
                        style: const TextStyle(color: Colors.white),
                      )
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}