import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/network_service.dart';
import '../utils/responsive_layout.dart';
import 'home_screen.dart';
import 'ver_screen.dart';
import 'perfil_screen.dart';
import 'nuevo_caso_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final GlobalKey<VerScreenState> _verScreenKey = GlobalKey<VerScreenState>();
  final GlobalKey<HomeScreenState> _homeScreenKey =
      GlobalKey<HomeScreenState>();

  late final List<Widget> _pages;

  /// IndexedStack mantiene Home montada; al volver a Inicio se sincronizan
  /// los KPIs con el servidor (p. ej. tras registrar desde la pestaña Nuevo caso).
  void _refreshHome() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _homeScreenKey.currentState?.refreshDesdeServidor();
    });
  }

  void _goToTab(
    int index, {
    bool focusVerSearch = false,
    FiltroVer? verEstadoFiltro,
    int? verSectorFiltroId,
    String? verSectorFiltroNombre,
  }) {
    setState(() => _index = index);
    if (index == 0) {
      _refreshHome();
      return;
    }
    if (index != 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ver = _verScreenKey.currentState;
      if (ver == null) return;
      if (verEstadoFiltro != null) {
        ver.applyEstadoFiltro(verEstadoFiltro);
      }
      if (verSectorFiltroId != null) {
        ver.applySectorFiltro(
          sectorId: verSectorFiltroId,
          sectorNombre: verSectorFiltroNombre,
        );
      }
      await ver.refreshCasosDesdeServidor();
      if (!mounted) return;
      if (focusVerSearch) {
        ver.requestSearchFocus();
      }
    });
  }

  /// Al elegir la pestaña Ver casos, sincronizar lista con el servidor (IndexedStack
  /// mantiene el estado anterior si solo se llamaba `_load()` desde Inicio).
  void _onTabSelected(int i) {
    setState(() => _index = i);
    if (i == 0) {
      _refreshHome();
      return;
    }
    if (i != 2) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verScreenKey.currentState?.refreshCasosDesdeServidor();
    });
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(key: _homeScreenKey, onGoToTab: _goToTab),
      const NuevoCasoScreen(),
      VerScreen(key: _verScreenKey),
      const PerfilScreen(),
    ];
  }

  Widget _offlineBanner() {
    return Material(
      elevation: 2,
      child: Container(
        width: double.infinity,
        color: Colors.orange.shade700,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(Icons.cloud_off, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Sin conexión',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageStack(bool isOnline) {
    return Stack(
      children: [
        IndexedStack(
          index: _index,
          children: _pages,
        ),
        if (!isOnline)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _offlineBanner(),
          ),
      ],
    );
  }

  static const Color _railPurple = Color(0xFF493EE5);
  static const Color _railMuted = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: NetworkService.instance.connectivityStream,
      initialData: NetworkService.instance.isOnline,
      builder: (context, snapshot) {
        final isOnline = snapshot.data ?? true;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            if (_index != 0) {
              setState(() => _index = 0);
              _refreshHome();
              return;
            }
            final salir = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Salir de la plataforma'),
                content: const Text('¿Deseas salir de Chagas Tracker?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Salir'),
                  ),
                ],
              ),
            );
            if (salir == true && context.mounted) {
              SystemNavigator.pop();
            }
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = isDesktopWidth(constraints.maxWidth);
              final useExtendedRail = constraints.maxWidth >= 1100;

              if (isDesktop) {
                return Scaffold(
                  body: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _index,
                        onDestinationSelected: _onTabSelected,
                        extended: useExtendedRail,
                        backgroundColor: Colors.white,
                        selectedIconTheme: const IconThemeData(
                          color: _railPurple,
                          size: 26,
                        ),
                        unselectedIconTheme: const IconThemeData(
                          color: _railMuted,
                          size: 24,
                        ),
                        selectedLabelTextStyle: const TextStyle(
                          color: _railPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                        unselectedLabelTextStyle: const TextStyle(
                          color: _railMuted,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                        indicatorColor: _railPurple.withValues(alpha: 0.12),
                        // Flutter 3.38+: extended == true requiere labelType none
                        // (texto va al lado del icono en el rail ancho).
                        labelType: useExtendedRail
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(
                            icon: Icon(Icons.dashboard_outlined),
                            selectedIcon: Icon(Icons.dashboard),
                            label: Text('Inicio'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.add_circle_outline),
                            selectedIcon: Icon(Icons.add_circle),
                            label: Text('Nuevo caso'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.list_alt_outlined),
                            selectedIcon: Icon(Icons.list_alt),
                            label: Text('Ver casos'),
                          ),
                          NavigationRailDestination(
                            icon: Icon(Icons.person_outline),
                            selectedIcon: Icon(Icons.person),
                            label: Text('Perfil'),
                          ),
                        ],
                      ),
                      const VerticalDivider(width: 1, thickness: 1),
                      Expanded(child: _pageStack(isOnline)),
                    ],
                  ),
                );
              }

              return Scaffold(
                body: _pageStack(isOnline),
                bottomNavigationBar: BottomNavigationBar(
                  type: BottomNavigationBarType.fixed,
                  currentIndex: _index,
                  onTap: _onTabSelected,
                  backgroundColor: Colors.white,
                  selectedItemColor: _railPurple,
                  unselectedItemColor: _railMuted,
                  selectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                  items: const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.dashboard_outlined),
                      activeIcon: Icon(Icons.dashboard),
                      label: 'Inicio',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.edit_note_outlined),
                      activeIcon: Icon(Icons.edit_note),
                      label: 'Nuevo caso',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search_outlined),
                      activeIcon: Icon(Icons.search),
                      label: 'Ver',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: 'Perfil',
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
