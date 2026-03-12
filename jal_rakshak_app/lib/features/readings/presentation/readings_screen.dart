import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../data/readings_repository.dart';
import '../domain/reading_model.dart';
import 'widgets/reading_card.dart';
import 'widgets/reading_details_modal.dart';

class ReadingsScreen extends ConsumerStatefulWidget {
  const ReadingsScreen({super.key});

  @override
  ConsumerState<ReadingsScreen> createState() => _ReadingsScreenState();
}

class _ReadingsScreenState extends ConsumerState<ReadingsScreen> {
  late Future<List<Reading>> _readingsFuture;

  @override
  void initState() {
    super.initState();
    _loadReadings();
  }

  Future<void> _loadReadings() async {
    setState(() {
      _readingsFuture = ref.read(readingsRepositoryProvider).getReadings();
    });
  }

  Future<void> _deleteReading(int id) async {
    try {
      await ref.read(readingsRepositoryProvider).deleteReading(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reading deleted', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.success,
          ),
        );
        _loadReadings(); // Refresh list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete reading', style: GoogleFonts.inter()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  void _showDetails(Reading reading) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => ReadingDetailsModal(reading: reading),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Saved Readings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _loadReadings,
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 18),
            label: Text('Refresh', style: GoogleFonts.inter(color: Colors.white70)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: null,
        child: SafeArea(
          child: FutureBuilder<List<Reading>>(
            future: _readingsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Failed to load readings',
                        style: GoogleFonts.inter(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: _loadReadings,
                        child: Text('Try Again', style: GoogleFonts.inter(color: AppTheme.primary)),
                      ),
                    ],
                  ),
                );
              }

              final readings = snapshot.data ?? [];

              if (readings.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, color: Colors.white.withOpacity(0.2), size: 64),
                      const SizedBox(height: 16),
                      Text(
                        'No saved readings yet',
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: readings.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return ReadingCard(
                    reading: readings[index],
                    onDelete: () => _deleteReading(readings[index].id),
                    onViewDetails: () => _showDetails(readings[index]),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
