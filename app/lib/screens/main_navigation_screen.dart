import 'package:flutter/material.dart';
import '../models/event.dart';
import '../providers/app_state.dart';
import '../widgets/app_bar.dart';
import '../widgets/bottom_nav_bar.dart';
import 'create_event_screen.dart';
import 'events_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final AppState appState;

  const MainNavigationScreen({
    super.key,
    required this.appState,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  bool _isCreatingEvent = false;

  void _startCreateEvent([Event? initialEvent]) {
    setState(() {
      _isCreatingEvent = true;
    });
  }

  void _closeCreateEvent() {
    setState(() {
      _isCreatingEvent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = widget.appState;
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final selectedEvent = appState.selectedEvent;

    // 1. If an event is selected or in Create / Edit mode
    if (_isCreatingEvent || selectedEvent != null) {
      return CreateEventScreen(
        appState: appState,
        initialEvent: selectedEvent,
        onBack: () {
          _closeCreateEvent();
          appState.selectEvent(null);
        },
        onReportGenerated: (generatedEv) {
          _closeCreateEvent();
          appState.selectEvent(null);
        },
      );
    }

    // 2. Main Navigation View (Home / Events / Settings)
    Widget bodyContent;
    switch (appState.currentTabIndex) {
      case 0:
        bodyContent = HomeScreen(
          appState: appState,
          onCreateEventTap: () {
            appState.selectEvent(null);
            _startCreateEvent();
          },
        );
        break;
      case 1:
        bodyContent = EventsScreen(
          appState: appState,
          onCreateEventTap: () {
            appState.selectEvent(null);
            _startCreateEvent();
          },
        );
        break;
      case 2:
      default:
        bodyContent = SettingsScreen(
          appState: appState,
        );
        break;
    }

    return Scaffold(
      appBar: ChronicoAppBar(
        currentTabIndex: appState.currentTabIndex,
        onTabSelected: (index) {
          appState.selectEvent(null);
          appState.setTabIndex(index);
        },
      ),
      body: bodyContent,
      bottomNavigationBar: !isDesktop
          ? ChronicoBottomNavBar(
              currentIndex: appState.currentTabIndex,
              onTap: (index) {
                appState.selectEvent(null);
                appState.setTabIndex(index);
              },
            )
          : null,
    );
  }
}
