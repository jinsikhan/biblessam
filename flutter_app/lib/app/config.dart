/// API base URL. Use env or constant for dev.
/// In production, set via --dart-define or flavor.
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

const String kApiDaily = '/api/daily';
const String kApiBibleChapter = '/api/bible/chapter';
const String kApiBibleBooks = '/api/bible/books';
const String kApiBibleSearch = '/api/bible/search';
const String kApiAiExplanation = '/api/ai/explanation';
const String kApiAiExplanationStream = '/api/ai/explanation/stream';
const String kApiAiPrayer = '/api/ai/prayer';
const String kApiRecommendationsEmotion = '/api/recommendations/emotion';
const String kApiFavorites = '/api/favorites';
const String kApiHistory = '/api/history';
const String kApiStreak = '/api/streak';

const int kStreakTargetMinutes = 10;
const int kMaxRecentChapters = 20;
const int kSnackBarUndoSeconds = 3;
