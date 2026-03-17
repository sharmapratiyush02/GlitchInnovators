// ── Chat Models ────────────────────────────────────────────────────────

enum MessageSender { user, ai }
enum MessageType { text, memory }

class Memory {
  final String text;
  final String date;
  final String sender;
  final double relevanceScore;

  const Memory({
    required this.text,
    required this.date,
    required this.sender,
    required this.relevanceScore,
  });

  /// Backend returns: { text, date, sender, score }
  factory Memory.fromJson(Map<String, dynamic> json) {
    return Memory(
      text:           json['text']   as String?  ?? '',
      date:           json['date']   as String?  ?? '',
      sender:         json['sender'] as String?  ?? '',
      relevanceScore: (json['score'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ChatMessage {
  final String id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final List<Memory> memories;
  final bool isLoading;
  final bool isCrisis;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.memories  = const [],
    this.isLoading = false,
    this.isCrisis  = false,
  });

  ChatMessage copyWith({
    String?       text,
    bool?         isLoading,
    List<Memory>? memories,
    bool?         isCrisis,
  }) {
    return ChatMessage(
      id:        id,
      text:      text       ?? this.text,
      sender:    sender,
      timestamp: timestamp,
      memories:  memories   ?? this.memories,
      isLoading: isLoading  ?? this.isLoading,
      isCrisis:  isCrisis   ?? this.isCrisis,
    );
  }
}

// ── Mood Journal Models ────────────────────────────────────────────────

enum Mood {
  joyful( emoji: '😊', label: 'Joyful',   color: 0xFFFFD166),
  peaceful(emoji: '😌', label: 'Peaceful', color: 0xFF7A9E7E),
  sad(     emoji: '😢', label: 'Sad',      color: 0xFF6B98C7),
  anxious( emoji: '😰', label: 'Anxious',  color: 0xFFB88C5A),
  angry(   emoji: '😤', label: 'Angry',    color: 0xFFCC6644),
  numb(    emoji: '😶', label: 'Numb',     color: 0xFF9E9E9E);

  const Mood({required this.emoji, required this.label, required this.color});
  final String emoji;
  final String label;
  final int    color;
}

class JournalEntry {
  final String  id;
  final DateTime date;
  final Mood    mood;
  final String? note;
  final List<String> tags;

  JournalEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    this.tags = const [],
  });
}

// ── Onboarding Model ───────────────────────────────────────────────────

enum Relationship { mother, father, partner, sibling, friend, child, other }

enum AppLanguage {
  english( code: 'en', name: 'English',  flag: '🇬🇧', subtitle: 'Default'),
  hindi(   code: 'hi', name: 'हिंदी',    flag: '🇮🇳', subtitle: 'Hindi'),
  marathi( code: 'mr', name: 'मराठी',    flag: '🇮🇳', subtitle: 'Marathi'),
  hinglish(code: 'hg', name: 'Hinglish', flag: '🇮🇳', subtitle: 'Mix of Hindi & English');

  const AppLanguage({
    required this.code,
    required this.name,
    required this.flag,
    required this.subtitle,
  });
  final String code;
  final String name;
  final String flag;
  final String subtitle;
}

class UserProfile {
  final String       userName;
  final String       lovedOneName;
  final Relationship relationship;
  final AppLanguage  language;
  final bool         memoriesImported;
  final int          memoriesCount;

  const UserProfile({
    required this.userName,
    required this.lovedOneName,
    required this.relationship,
    required this.language,
    this.memoriesImported = false,
    this.memoriesCount    = 0,
  });

  UserProfile copyWith({
    String?       userName,
    String?       lovedOneName,
    Relationship? relationship,
    AppLanguage?  language,
    bool?         memoriesImported,
    int?          memoriesCount,
  }) {
    return UserProfile(
      userName:         userName         ?? this.userName,
      lovedOneName:     lovedOneName     ?? this.lovedOneName,
      relationship:     relationship     ?? this.relationship,
      language:         language         ?? this.language,
      memoriesImported: memoriesImported ?? this.memoriesImported,
      memoriesCount:    memoriesCount    ?? this.memoriesCount,
    );
  }
}
