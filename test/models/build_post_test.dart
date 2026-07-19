import 'package:flutter_test/flutter_test.dart';
import 'package:moto_vitals/models/build_post.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';

class MockTimestamp extends Mock implements Timestamp {}

void main() {
  group('BuildPost', () {
    final now = DateTime.now();
    final timestamp = Timestamp.fromDate(now);

    test('fromJson creates a valid BuildPost', () {
      final json = {
        'userId': 'user123',
        'username': 'rider1',
        'title': 'Cool Bike',
        'description': 'A very cool bike',
        'imageUrl': 'http://image.png',
        'taggedPartIds': ['part1', 'part2'],
        'createdAt': timestamp,
        'likeCount': 10,
      };

      final buildPost = BuildPost.fromJson(json, 'post123');

      expect(buildPost.id, 'post123');
      expect(buildPost.userId, 'user123');
      expect(buildPost.username, 'rider1');
      expect(buildPost.title, 'Cool Bike');
      expect(buildPost.description, 'A very cool bike');
      expect(buildPost.imageUrl, 'http://image.png');
      expect(buildPost.taggedPartIds, ['part1', 'part2']);
      expect(buildPost.createdAt, now);
      expect(buildPost.likeCount, 10);
    });

    test('fromJson handles null values with defaults', () {
      final json = <String, dynamic>{};
      final buildPost = BuildPost.fromJson(json, 'post123');

      expect(buildPost.userId, '');
      expect(buildPost.username, 'Rider');
      expect(buildPost.title, 'My Build');
      expect(buildPost.createdAt, isA<DateTime>());
      expect(buildPost.likeCount, 0);
    });

    test('toJson returns a valid map', () {
      final buildPost = BuildPost(
        id: 'post123',
        userId: 'user123',
        username: 'rider1',
        title: 'Cool Bike',
        description: 'A very cool bike',
        imageUrl: 'http://image.png',
        taggedPartIds: ['part1', 'part2'],
        createdAt: now,
        likeCount: 10,
      );

      final json = buildPost.toJson();

      expect(json['userId'], 'user123');
      expect(json['username'], 'rider1');
      expect(json['title'], 'Cool Bike');
      expect(json['description'], 'A very cool bike');
      expect(json['imageUrl'], 'http://image.png');
      expect(json['taggedPartIds'], ['part1', 'part2']);
      expect(json['createdAt'], isA<Timestamp>());
      expect((json['createdAt'] as Timestamp).toDate(), now);
      expect(json['likeCount'], 10);
    });
  });
}
