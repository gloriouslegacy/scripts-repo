
모든 프로젝트에 적용하려면 C:\Users\bigboss01\.claude\settings.json에 아래 항목을 추가하세요. 기존 내용이 있으면 그 안에 한 줄만 넣으면 됩니다.

json
{
  "outputStyle": "No Code"
}

  "promptSuggestionEnabled": false,
  "outputStyle": "No Code",
  "spinnerTipsEnabled": false,
  "showTurnDuration": false


~/.claude/output-styles/noCode.md
---
name: No Code
description: 코드 출력 없이 결과만 요약
---
  코드 전문이나 diff를 답변에 출력하지 말 것. 파일 수정은 도구로만 하고,
  답변은 무엇을 바꿨는지와 결과만 2~3문장으로 요약할 것.

그다음 Claude Code를 다시 시작하고 /output-style을 실행해 목록에 "No Code"가 보이면 선택하시면 됩니다.
