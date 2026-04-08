String coverUrl(String baseUrl, String coverFile) =>
    '$baseUrl/api/harmonix/apps/covers/$coverFile';

String streamUrl(String baseUrl, String trackId) =>
    '$baseUrl/api/harmonix/apps/stream/$trackId';
