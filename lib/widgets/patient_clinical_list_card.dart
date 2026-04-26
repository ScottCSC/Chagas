import 'package:flutter/material.dart';

/// Estados visuales de la barra lateral / pastilla (mismo criterio que Ver pacientes).
enum PatientVisualStatus { upToDate, upcoming, overdue }

class PatientCardData {
  final String name;
  final String? rut;
  final String? location;

  /// Fila central (ej. control, fecha clave, inasistencia).
  final String controlText;

  /// Fila inferior (ej. exámenes, teléfono, notas).
  final String examText;

  /// Icono de la tercera fila (por defecto laboratorio / exámenes).
  final IconData detailRowIcon;

  final PatientVisualStatus status;

  /// Si no es null, reemplaza el texto de la pastilla (ej. estado de examen).
  final String? statusLabelOverride;

  /// Icono de la fila `controlText` (por defecto según [status]).
  final IconData? eventRowIcon;

  final Set<String> modulos;

  const PatientCardData({
    required this.name,
    this.rut,
    this.location,
    required this.controlText,
    required this.examText,
    this.detailRowIcon = Icons.science_outlined,
    required this.status,
    this.statusLabelOverride,
    this.eventRowIcon,
    this.modulos = const {},
  });
}

Color patientStatusColor(PatientVisualStatus status) {
  switch (status) {
    case PatientVisualStatus.upToDate:
      return const Color(0xFF2E7D32);
    case PatientVisualStatus.upcoming:
      return const Color(0xFFF9A825);
    case PatientVisualStatus.overdue:
      return const Color(0xFFC62828);
  }
}

String patientStatusLabel(PatientVisualStatus status) {
  switch (status) {
    case PatientVisualStatus.upToDate:
      return 'Al día';
    case PatientVisualStatus.upcoming:
      return 'Próximo control';
    case PatientVisualStatus.overdue:
      return 'Control atrasado';
  }
}

IconData patientStatusIcon(PatientVisualStatus status) {
  switch (status) {
    case PatientVisualStatus.upToDate:
      return Icons.check_circle_outline_rounded;
    case PatientVisualStatus.upcoming:
      return Icons.schedule_rounded;
    case PatientVisualStatus.overdue:
      return Icons.warning_amber_rounded;
  }
}

class PatientListCard extends StatelessWidget {
  final PatientCardData data;
  final VoidCallback? onTap;

  /// Acciones bajo las filas (ej. “Marcar como realizado”).
  final Widget? footer;

  const PatientListCard({
    super.key,
    required this.data,
    this.onTap,
    this.footer,
  });

  static const _radius = 18.0;

  @override
  Widget build(BuildContext context) {
    final statusColor = patientStatusColor(data.status);
    final isOverdue = data.status == PatientVisualStatus.overdue;
    final isUpcoming = data.status == PatientVisualStatus.upcoming;
    final chipText =
        data.statusLabelOverride ?? patientStatusLabel(data.status);

    IconData controlIconDefault() {
      if (isOverdue) return Icons.error_outline_rounded;
      if (isUpcoming) return Icons.access_time_rounded;
      return Icons.event_outlined;
    }

    final midIcon = data.eventRowIcon ?? controlIconDefault();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_radius),
        border: Border(
          left: BorderSide(color: statusColor, width: 7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(_radius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 18, 10, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                          ),
                          if (data.rut != null &&
                              data.rut!.trim().isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              data.rut!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 148),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            patientStatusIcon(data.status),
                            size: 17,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              chipText,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Colors.grey.shade400, size: 26),
                  ],
                ),
                const SizedBox(height: 16),
                ClinicalListInfoRow(
                  icon: Icons.location_on_outlined,
                  text: data.location?.isNotEmpty == true
                      ? data.location!
                      : 'Sin ubicación',
                ),
                const SizedBox(height: 10),
                ClinicalListInfoRow(
                  icon: midIcon,
                  text: data.controlText,
                  iconColor: isOverdue ? statusColor : null,
                  textColor: isOverdue ? statusColor : null,
                  fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ClinicalListInfoRow(
                  icon: data.detailRowIcon,
                  text: data.examText,
                  maxLines: 3,
                ),
                if (data.modulos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: data.modulos.map((m) {
                      const labels = {
                        'BC': 'BC',
                        'G': 'G',
                        'A': 'A',
                        'T': 'T',
                        'I': 'I',
                        'E': 'E',
                      };
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          labels[m] ?? m,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
                if (footer != null) ...[
                  const SizedBox(height: 12),
                  footer!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ClinicalListInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? iconColor;
  final Color? textColor;
  final FontWeight fontWeight;
  final int maxLines;

  const ClinicalListInfoRow({
    super.key,
    required this.icon,
    required this.text,
    this.iconColor,
    this.textColor,
    this.fontWeight = FontWeight.w400,
    this.maxLines = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            icon,
            size: 19,
            color: iconColor ?? Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              height: 1.35,
              color: textColor ?? Colors.grey.shade800,
              fontWeight: fontWeight,
            ),
          ),
        ),
      ],
    );
  }
}
