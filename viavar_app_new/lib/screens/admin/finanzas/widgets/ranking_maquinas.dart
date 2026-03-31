import 'package:flutter/material.dart';
import '../../../../models/finanzas_modelos.dart';

class RankingMaquinas extends StatelessWidget {
  final List<MaquinaTopFacturacion> maquinas;
  final double totalGeneral;

  const RankingMaquinas({
    super.key,
    required this.maquinas,
    required this.totalGeneral,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Máquinas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (maquinas.isEmpty)
          const Center(
            child: Text('No hay datos disponibles'),
          )
        else
          ...maquinas.map((maquina) => _buildRankingItem(maquina)),
      ],
    );
  }

  Widget _buildRankingItem(MaquinaTopFacturacion maquina) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${maquinas.indexOf(maquina) + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  maquina.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '\$${maquina.ventasTotales.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: maquina.porcentaje / 100,
                    backgroundColor: Colors.grey[300],
                    color: Colors.blue,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${maquina.porcentaje.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
