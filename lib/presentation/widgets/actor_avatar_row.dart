import 'package:flutter/material.dart';

import '../../domain/entities/actor.dart';

/// Displays a horizontal row of overlapping actor avatars.
class ActorAvatarRow extends StatelessWidget {
  final List<Actor> actors;
  final double size;

  const ActorAvatarRow({
    super.key,
    required this.actors,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    if (actors.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: size,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < actors.length; i++)
            Transform.translate(
              offset: Offset(i * -(size * 0.3), 0),
              child: CircleAvatar(
                radius: size / 2,
                backgroundColor: Color(actors[i].colorValue),
                child: Text(
                  actors[i].name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: size * 0.4,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
