// Flow 앱 버전. pubspec.yaml의 `version: <appVersion>+<appBuild>`와 항상 같아야 한다.
// (test/app_version_test.dart가 검사한다. 올리는 규칙은 .claude/skills/flow-versioning)
const String appVersion = '1.3.4';
const int appBuild = 19;

/// 화면에 보이는 버전 글자 (창 제목, 설정 창).
const String appVersionLabel = 'v$appVersion';
