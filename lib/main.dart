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
      title: 'App de Clima',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const WeatherPage(),
    );
  }
}

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class PrevisaoDia {
  final String data;
  final double tempMax;
  final double tempMin;
  final int weatherCode;

  PrevisaoDia({
    required this.data,
    required this.tempMax,
    required this.tempMin,
    required this.weatherCode,
  });
}

class _WeatherPageState extends State<WeatherPage> {
  bool isLoading = true;
  String mensagem = '';
  String cidade = 'Clima da sua região';

  double? temperatura;
  double? vento;
  int? weatherCode;

  List<PrevisaoDia> previsoes = [];

  @override
  void initState() {
    super.initState();
    buscarClima();
  }

  Future<void> buscarClima() async {
    setState(() {
      isLoading = true;
      mensagem = '';
    });

    try {
      final position = await _obterLocalizacao();

      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&current=temperature_2m,weather_code,wind_speed_10m'
        '&daily=weather_code,temperature_2m_max,temperature_2m_min'
        '&timezone=auto',
      );

      final weatherResponse = await http.get(weatherUrl);

      if (weatherResponse.statusCode != 200) {
        throw Exception(
          'Erro ao buscar clima. Código: ${weatherResponse.statusCode}',
        );
      }

      final weatherData = jsonDecode(weatherResponse.body);

      if (weatherData['current'] == null) {
        throw Exception('A API não retornou os dados atuais do clima.');
      }

      if (weatherData['daily'] == null) {
        throw Exception('A API não retornou a previsão diária.');
      }

      final current = weatherData['current'];
      final daily = weatherData['daily'];

      final List datas = daily['time'] ?? [];
      final List temperaturasMax = daily['temperature_2m_max'] ?? [];
      final List temperaturasMin = daily['temperature_2m_min'] ?? [];
      final List codigos = daily['weather_code'] ?? [];

      final List<PrevisaoDia> listaPrevisoes = [];

      final total = [
        datas.length,
        temperaturasMax.length,
        temperaturasMin.length,
        codigos.length,
      ].reduce((a, b) => a < b ? a : b);

      for (int i = 0; i < total && i < 5; i++) {
        listaPrevisoes.add(
          PrevisaoDia(
            data: datas[i].toString(),
            tempMax: (temperaturasMax[i] as num).toDouble(),
            tempMin: (temperaturasMin[i] as num).toDouble(),
            weatherCode: (codigos[i] as num).toInt(),
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        cidade = 'Sua localização';
        temperatura = (current['temperature_2m'] as num?)?.toDouble();
        vento = (current['wind_speed_10m'] as num?)?.toDouble();
        weatherCode = (current['weather_code'] as num?)?.toInt();
        previsoes = listaPrevisoes;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        mensagem = 'Erro: $e';
        cidade = 'Não foi possível localizar';
        temperatura = null;
        vento = null;
        weatherCode = null;
        previsoes = [];
        isLoading = false;
      });
    }
  }

  Future<Position> _obterLocalizacao() async {
    final servicoAtivo = await Geolocator.isLocationServiceEnabled();

    if (!servicoAtivo) {
      throw Exception('Ative a localização do dispositivo.');
    }

    LocationPermission permissao = await Geolocator.checkPermission();

    if (permissao == LocationPermission.denied) {
      permissao = await Geolocator.requestPermission();

      if (permissao == LocationPermission.denied) {
        throw Exception('Permissão de localização negada.');
      }
    }

    if (permissao == LocationPermission.deniedForever) {
      throw Exception(
        'Permissão negada permanentemente. Libere nas configurações do app.',
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  String traduzirClima(int? code) {
    switch (code) {
      case 0:
        return 'Céu limpo';
      case 1:
      case 2:
      case 3:
        return 'Parcialmente nublado';
      case 45:
      case 48:
        return 'Neblina';
      case 51:
      case 53:
      case 55:
        return 'Garoa';
      case 61:
      case 63:
      case 65:
        return 'Chuva';
      case 71:
      case 73:
      case 75:
        return 'Neve';
      case 80:
      case 81:
      case 82:
        return 'Pancadas de chuva';
      case 95:
        return 'Tempestade';
      default:
        return 'Condição desconhecida';
    }
  }

  IconData iconeClima(int? code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code == 1 || code == 2 || code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code == 61 ||
        code == 63 ||
        code == 65 ||
        code == 80 ||
        code == 81 ||
        code == 82) {
      return Icons.grain_rounded;
    }
    if (code == 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }

  List<Color> coresDeFundo(int? code) {
    if (code == 0) {
      return const [Color(0xFF4FACFE), Color(0xFF00F2FE)];
    }

    if (code == 1 || code == 2 || code == 3) {
      return const [Color(0xFF74EBD5), Color(0xFF9FACE6)];
    }

    if (code == 61 ||
        code == 63 ||
        code == 65 ||
        code == 80 ||
        code == 81 ||
        code == 82) {
      return const [Color(0xFF4B79A1), Color(0xFF283E51)];
    }

    if (code == 95) {
      return const [Color(0xFF232526), Color(0xFF414345)];
    }

    return const [Color(0xFF4FACFE), Color(0xFF00F2FE)];
  }

  String nomeDoDia(String data) {
    final date = DateTime.parse(data);

    switch (date.weekday) {
      case 1:
        return 'Seg';
      case 2:
        return 'Ter';
      case 3:
        return 'Qua';
      case 4:
        return 'Qui';
      case 5:
        return 'Sex';
      case 6:
        return 'Sáb';
      case 7:
        return 'Dom';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final climaTexto = traduzirClima(weatherCode);
    final fundo = coresDeFundo(weatherCode);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: fundo,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        Center(
                          child: Text(
                            cidade,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Clima atual',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.16),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                iconeClima(weatherCode),
                                size: 110,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                '${temperatura?.toStringAsFixed(1) ?? '--'} °C',
                                style: const TextStyle(
                                  fontSize: 52,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                climaTexto,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white.withOpacity(0.95),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.air_rounded,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vento: ${vento?.toStringAsFixed(1) ?? '--'} km/h',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        const Text(
                          'Próximos dias',
                          style: TextStyle(
                            fontSize: 22,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 190,
                          child: previsoes.isEmpty
                              ? Center(
                                  child: Text(
                                    'Sem previsão disponível',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 16,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: previsoes.length,
                                  itemBuilder: (context, index) {
                                    final previsao = previsoes[index];

                                    return Container(
                                      width: 120,
                                      margin: const EdgeInsets.only(right: 14),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.20),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            nomeDoDia(previsao.data),
                                            style: const TextStyle(
                                              fontSize: 17,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Icon(
                                            iconeClima(previsao.weatherCode),
                                            size: 34,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            '${previsao.tempMax.toStringAsFixed(0)}°',
                                            style: const TextStyle(
                                              fontSize: 20,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${previsao.tempMin.toStringAsFixed(0)}°',
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.white.withOpacity(
                                                0.80,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 28),
                        Center(
                          child: SizedBox(
                            width: 190,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: buscarClima,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'Atualizar',
                                style: TextStyle(fontSize: 17),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blueAccent,
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (mensagem.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              mensagem,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
