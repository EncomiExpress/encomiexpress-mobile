import 'package:flutter/material.dart';
import 'models.dart';
import 'widgets.dart';

class ImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageViewer({
    super.key, 
    required this.imageUrls,
    this.initialIndex = 0,
  });

  static void show(BuildContext context, List<String> imageUrls, {int initialIndex = 0}) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => ImageViewer(
        imageUrls: imageUrls,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  State<ImageViewer> createState() => _ImageViewerState();
}

class _ImageViewerState extends State<ImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onVerticalDragEnd: (details) {
              if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                Navigator.pop(context);
              }
            },
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _ImagePage(url: widget.imageUrls[index]);
              },
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close, color: Colors.white, size: 28),
            ),
          ),
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  widget.imageUrls.length,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex ? Colors.white : Colors.white54,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ImagePage extends StatefulWidget {
  final String url;

  const _ImagePage({required this.url});

  @override
  State<_ImagePage> createState() => _ImagePageState();
}

class _ImagePageState extends State<_ImagePage> {
  // Sube en cada "Reintentar" para forzar un Key nuevo — así Image.network
  // vuelve a intentar la descarga en vez de quedarse con el error cacheado.
  int _intento = 0;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.network(
          widget.url,
          key: ValueKey(_intento),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _buildError(),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const CircularProgressIndicator(color: Colors.white);
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image_rounded, color: Colors.white54, size: 64),
        const SizedBox(height: 12),
        const Text('Error al cargar imagen',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() => _intento++),
          child: const Text('Reintentar', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class ImageThumbnail extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const ImageThumbnail({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapArea(
      onTap: onTap ?? () => ImageViewer.show(context, [imageUrl]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => Container(
            width: size,
            height: size,
            color: AppColors.bgGray,
            child: Icon(Icons.image_not_supported, color: AppColors.textSub),
          ),
        ),
      ),
    );
  }
}

class ImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double thumbnailSize;
  final int maxDisplay;

  const ImageGallery({
    super.key,
    required this.imageUrls,
    this.thumbnailSize = 60,
    this.maxDisplay = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();

    final displayUrls = imageUrls.take(maxDisplay).toList();
    final remaining = imageUrls.length - maxDisplay;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...displayUrls.map((url) => ImageThumbnail(
          imageUrl: url,
          size: thumbnailSize,
          onTap: () {
            final index = displayUrls.indexOf(url);
            ImageViewer.show(context, imageUrls, initialIndex: index);
          },
        )),
        if (remaining > 0)
          TapArea(
            onTap: () => ImageViewer.show(context, imageUrls),
            child: Container(
              width: thumbnailSize,
              height: thumbnailSize,
              decoration: BoxDecoration(
                color: AppColors.bgGray,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Text('+$remaining',
                    style: TextStyle(
                        color: AppColors.textSub,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
      ],
    );
  }
}