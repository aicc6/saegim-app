import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:saegim/app/routes/route_paths.dart';
import 'package:saegim/core/theme/theme_extensions.dart';

/// 메인 앱의 공통 Scaffold (하단 네비게이션 포함)
class MainScaffold extends StatefulWidget {
  final Widget child;
  final Uri currentUri;

  const MainScaffold({
    super.key,
    required this.child,
    required this.currentUri,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  late Uri _effectiveUri;
  bool _isDiaryOverlay = false;
  ValueListenable<RouteInformation>? _routeListenable;

  @override
  void initState() {
    super.initState();
    _effectiveUri = widget.currentUri;
    _isDiaryOverlay = _shouldShowOverlay(_effectiveUri);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final router = GoRouter.of(context);
      _routeListenable = router.routeInformationProvider
        ..addListener(_handleRouteChange);
      _handleRouteChange();
    });
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentUri != widget.currentUri) {
      _updateFromUri(widget.currentUri);
    }
  }

  @override
  void dispose() {
    _routeListenable?.removeListener(_handleRouteChange);
    super.dispose();
  }

  void _handleRouteChange() {
    if (!mounted) return;
    final uri = _uriFromRouteInformation(_routeListenable?.value);
    if (uri != null) {
      _updateFromUri(uri);
    }
  }

  void _updateFromUri(Uri uri) {
    final overlay = _shouldShowOverlay(uri);
    if (_effectiveUri == uri && _isDiaryOverlay == overlay) {
      return;
    }

    setState(() {
      _effectiveUri = uri;
      _isDiaryOverlay = overlay;
    });
  }

  Uri? _uriFromRouteInformation(RouteInformation? info) {
    final location = info?.location;
    if (location == null || location.isEmpty) {
      return null;
    }
    return Uri.parse(location);
  }

  bool _shouldShowOverlay(Uri uri) {
    return uri.path == '/diary' && uri.queryParameters['mode'] == 'overlay';
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(_effectiveUri);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: currentIndex,
        selectedItemColor: context.colorScheme.primary,
        unselectedItemColor: context.secondaryText,
        elevation: 8,
        onTap: _onTap,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.edit_outlined),
            activeIcon: Icon(Icons.edit),
            label: '글쓰기',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              _isDiaryOverlay ? Icons.menu_book_outlined : Icons.list_outlined,
            ),
            activeIcon: Icon(
              _isDiaryOverlay ? Icons.menu_book : Icons.list,
            ),
            label: '글목록',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
        ],
      ),
    );
  }

  int _getCurrentIndex(Uri uri) {
    if (uri.path.startsWith('/diary')) return 1;
    if (uri.path.startsWith(RoutePaths.calendar)) return 2;
    return 0;
  }

  void _onTap(int index) {
    final router = GoRouter.of(context);

    switch (index) {
      case 0:
        setState(() {
          _isDiaryOverlay = false;
          _effectiveUri = Uri.parse(RoutePaths.home);
        });
        router.go(RoutePaths.home);
        break;
      case 1:
        final onDiaryPath = _effectiveUri.path.startsWith('/diary');
        final isDiaryRoot = _effectiveUri.path == '/diary';

        if (!onDiaryPath) {
          setState(() {
            _isDiaryOverlay = false;
            _effectiveUri = Uri(path: '/diary');
          });
          router.go('/diary');
          break;
        }

        if (!_isDiaryOverlay) {
          final params = isDiaryRoot
              ? Map<String, String>.from(_effectiveUri.queryParameters)
              : <String, String>{};
          params['mode'] = 'overlay';

          final target = Uri(path: '/diary', queryParameters: params);
          setState(() {
            _isDiaryOverlay = true;
            _effectiveUri = target;
          });
          router.go(target.toString());
        } else {
          if (isDiaryRoot) {
            final params = Map<String, String>.from(_effectiveUri.queryParameters)
              ..remove('mode');
            final target = Uri(
              path: '/diary',
              queryParameters: params.isEmpty ? null : params,
            );
            setState(() {
              _isDiaryOverlay = false;
              _effectiveUri = target;
            });
            router.go(target.toString());
          } else {
            setState(() {
              _isDiaryOverlay = false;
              _effectiveUri = Uri(path: '/diary');
            });
            router.go('/diary');
          }
        }
        break;
      case 2:
        setState(() {
          _isDiaryOverlay = false;
          _effectiveUri = Uri.parse(RoutePaths.calendar);
        });
        router.go(RoutePaths.calendar);
        break;
    }
  }
}
