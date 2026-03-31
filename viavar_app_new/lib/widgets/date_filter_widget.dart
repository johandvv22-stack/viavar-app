import "package:flutter/material.dart";

class DateFilterWidget extends StatefulWidget {
  final Function(DateTime, DateTime) onDateRangeChanged;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const DateFilterWidget({
    super.key,
    required this.onDateRangeChanged,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<DateFilterWidget> createState() => _DateFilterWidgetState();
}

class _DateFilterWidgetState extends State<DateFilterWidget> {
  late DateTime _startDate;
  late DateTime _endDate;
  String _selectedFilter = "Este Mes";
  bool _initialized = false;

  final List<Map<String, dynamic>> _filterOptions = [
    {"label": "Hoy", "days": 0},
    {"label": "7 Días", "days": 7},
    {"label": "Este Mes", "days": 30},
    {"label": "Mes Pasado", "days": 60},
    {"label": "Personalizado", "days": -1},
  ];

  @override
  void initState() {
    super.initState();
    _endDate = widget.initialEndDate ?? DateTime.now();
    _startDate = widget.initialStartDate ?? DateTime.now().subtract(const Duration(days: 30));
    
    // POSPONER la llamada inicial hasta después del primer build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _applyFilter("Este Mes", isInitial: true);
      }
    });
  }

  void _applyFilter(String filterLabel, {bool isInitial = false}) {
    setState(() {
      _selectedFilter = filterLabel;
      final now = DateTime.now();
      
      if (filterLabel == "Hoy") {
        _startDate = DateTime(now.year, now.month, now.day);
        _endDate = now;
      } else if (filterLabel == "7 Días") {
        _startDate = now.subtract(const Duration(days: 7));
        _endDate = now;
      } else if (filterLabel == "Este Mes") {
        _startDate = DateTime(now.year, now.month, 1);
        _endDate = now;
      } else if (filterLabel == "Mes Pasado") {
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        _startDate = lastMonth;
        _endDate = DateTime(now.year, now.month, 0);
      }
      // "Personalizado" no cambia las fechas automáticamente
    });
    
    // Solo llamar al callback si no es la inicialización o si ya se inicializó
    if (!isInitial || _initialized) {
      widget.onDateRangeChanged(_startDate, _endDate);
    }
    
    if (isInitial) {
      _initialized = true;
    }
  }

  Future<void> _selectCustomDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
        _selectedFilter = "Personalizado";
      });
      
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Botones de filtro rápido
        SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filterOptions.length,
            itemBuilder: (context, index) {
              final option = _filterOptions[index];
              final isSelected = _selectedFilter == option["label"];
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(option["label"]),
                  selected: isSelected,
                  onSelected: (_) => _applyFilter(option["label"]),
                  selectedColor: Colors.blue[100],
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.blue[900] : Colors.grey[700],
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 10),
        
        // Mostrar rango de fechas seleccionado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: InkWell(
                onTap: () => _selectCustomDate(context, true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${_startDate.day}/${_startDate.month}/${_startDate.year}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Text("a", style: TextStyle(color: Colors.grey)),
            ),
            
            Expanded(
              child: InkWell(
                onTap: () => _selectCustomDate(context, false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "${_endDate.day}/${_endDate.month}/${_endDate.year}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
