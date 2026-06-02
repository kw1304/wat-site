<#
.SYNOPSIS
  WAT 사이트에 새 툴 카드 + 설명서를 한 번에 추가한다.

.DESCRIPTION
  1) guide/_template.html 로 guide/<slug>.html 생성 (스펙 JSON 치환)
  2) index.html 의 해당 분류 CARD-INSERT 마커에 카드 삽입
  3) 모든 가이드의 more-tools(상호 링크) 재동기화
  4) (-Push) git add/commit/push → Render 자동 재배포

.EXAMPLE
  pwsh ./add-tool.ps1 -Spec ./_tool-spec.example.json
  pwsh ./add-tool.ps1 -Spec ./mytool.json -Push
#>
param(
  [Parameter(Mandatory=$true)][string]$Spec,
  [switch]$Push
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
function WriteUtf8($path, $text){
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}
function ReadAll($path){ [System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8) }

# ── 분류별 고정값 (아이콘=분류 머리글자 통일) ──
$CAT = @{
  valuation = @{ label='평가';     ico='v'; icon='V'; hex='3182F6' }
  audit     = @{ label='감사보조'; ico='a'; icon='A'; hex='7C3AED' }
  reference = @{ label='리서치';   ico='r'; icon='R'; hex='00C2B3' }
}

# ── 스펙 로드 ──
$s = Get-Content -Raw -Encoding UTF8 $Spec | ConvertFrom-Json
foreach($k in 'slug','tool_id','category','name','en','desc'){
  if(-not $s.$k){ throw "스펙에 필수 항목 누락: $k" }
}
if(-not $CAT.ContainsKey($s.category)){ throw "category는 valuation|audit|reference 중 하나" }
$c = $CAT[$s.category]
$guidePath = Join-Path $root "guide/$($s.slug).html"
if(Test-Path $guidePath){ throw "이미 존재: guide/$($s.slug).html" }

# ── 1) 가이드 생성 ──
$tpl = ReadAll (Join-Path $root 'guide/_template.html')
function J($arr,$i,$f){ if($arr.Count -gt $i){ $arr[$i].$f } else { '' } }
$map = @{
  '{{NAME}}'=$s.name; '{{EN}}'=$s.en; '{{TOOL_ID}}'=$s.tool_id;
  '{{CATEGORY}}'=$s.category; '{{CAT_LABEL}}'=$c.label;
  '{{ICO_CLASS}}'=$c.ico; '{{ICON}}'=$c.icon; '{{ICON_HEX}}'=$c.hex;
  '{{LEAD}}'=$s.lead;
  '{{WHO_1}}'=(J $s.who 0 'v'); '{{WHO_2}}'=(J $s.who 1 'v'); '{{WHO_3}}'=(J $s.who 2 'v'); '{{WHO_4}}'=(J $s.who 3 'v');
  '{{CONCEPT_1_TITLE}}'=(J $s.concepts 0 't'); '{{CONCEPT_1_BODY}}'=(J $s.concepts 0 'b');
  '{{CONCEPT_2_TITLE}}'=(J $s.concepts 1 't'); '{{CONCEPT_2_BODY}}'=(J $s.concepts 1 'b');
  '{{PREP_1}}'=(J $s.prep 0 'v'); '{{PREP_2}}'=(J $s.prep 1 'v'); '{{PREP_3}}'=(J $s.prep 2 'v');
  '{{STEP_1_TITLE}}'=(J $s.steps 0 't'); '{{STEP_1_BODY}}'=(J $s.steps 0 'b');
  '{{STEP_2_TITLE}}'=(J $s.steps 1 't'); '{{STEP_2_BODY}}'=(J $s.steps 1 'b');
  '{{STEP_3_TITLE}}'=(J $s.steps 2 't'); '{{STEP_3_BODY}}'=(J $s.steps 2 'b');
  '{{STEP_4_TITLE}}'=(J $s.steps 3 't'); '{{STEP_4_BODY}}'=(J $s.steps 3 'b');
  '{{OUT_1_TITLE}}'=(J $s.out 0 't'); '{{OUT_1_BODY}}'=(J $s.out 0 'b');
  '{{OUT_2_TITLE}}'=(J $s.out 1 't'); '{{OUT_2_BODY}}'=(J $s.out 1 'b');
  '{{OUT_3_TITLE}}'=(J $s.out 2 't'); '{{OUT_3_BODY}}'=(J $s.out 2 'b');
  '{{OUT_4_TITLE}}'=(J $s.out 3 't'); '{{OUT_4_BODY}}'=(J $s.out 3 'b');
  '{{FAQ_1_Q}}'=(J $s.faq 0 'q'); '{{FAQ_1_A}}'=(J $s.faq 0 'a');
  '{{FAQ_2_Q}}'=(J $s.faq 1 'q'); '{{FAQ_2_A}}'=(J $s.faq 1 'a');
  '{{FAQ_3_Q}}'=(J $s.faq 2 'q'); '{{FAQ_3_A}}'=(J $s.faq 2 'a');
  '{{CTA_TITLE}}'=$s.cta_title; '{{CTA_SUB}}'=$s.cta_sub;
  '{{MORE_TOOLS}}'=''   # 아래에서 일괄 재동기화
}
foreach($k in $map.Keys){ $tpl = $tpl.Replace($k, [string]$map[$k]) }
WriteUtf8 $guidePath $tpl
Write-Host "생성: guide/$($s.slug).html"

# ── 2) index.html 카드 삽입 ──
$feats = ($s.feats | ForEach-Object { "<span class=`"feat`">$_</span>" }) -join ''
$card = @"
    <!-- $($s.name) -->
    <article class="tcard">
      <div class="top">
        <div class="ico ico-$($c.ico)">$($c.icon)</div>
        <h3>$($s.name)<span class="en">$($s.en)</span></h3>
      </div>
      <p class="desc">$($s.desc)</p>
      <div class="feats">$feats</div>
      <div class="actions">
        <a class="a-guide" href="guide/$($s.slug).html">설명서 보기</a>
        <a class="a-open" href="https://wat.taild5874c.ts.net/#tool=$($s.tool_id)" target="_blank" rel="noopener">도구 열기</a>
      </div>
    </article>
    <!-- CARD-INSERT:$($s.category) -->
"@
$indexPath = Join-Path $root 'index.html'
$idx = ReadAll $indexPath
$marker = "    <!-- CARD-INSERT:$($s.category) -->"
if($idx -notmatch [regex]::Escape($marker)){ throw "index.html에 마커 없음: CARD-INSERT:$($s.category)" }
$idx = $idx.Replace($marker, $card.TrimEnd("`r","`n"))
WriteUtf8 $indexPath $idx
Write-Host "카드 삽입: [$($s.category)] $($s.name)"

# ── 3) 모든 가이드 more-tools 재동기화 ──
$guides = Get-ChildItem (Join-Path $root 'guide') -Filter '*.html' |
  Where-Object { $_.Name -ne '_template.html' }
# 슬러그→표시명 레지스트리 (<h1> 첫 텍스트 = name, <span class="en"> 전까지)
$reg = @{}
foreach($g in $guides){
  $html = ReadAll $g.FullName
  if($html -match '<div><h1>([^<]+)<span class="en">'){ $reg[$g.BaseName] = $Matches[1].Trim() }
  elseif($html -match '<h1>([^<]+)<span class="en">'){ $reg[$g.BaseName] = $Matches[1].Trim() }
  else { $reg[$g.BaseName] = $g.BaseName }
}
foreach($g in $guides){
  $html = ReadAll $g.FullName
  $links = foreach($slug in ($reg.Keys | Sort-Object)){
    if($slug -ne $g.BaseName){ "<a href=`"$slug.html`">$($reg[$slug])</a>" }
  }
  $block = "<div class=`"more-tools`">" + ($links -join '') + "</div>"
  $new = [regex]::Replace($html, '<div class="more-tools">.*?</div>', { $block }, 'Singleline')
  if($new -ne $html){ WriteUtf8 $g.FullName $new }
}
Write-Host "more-tools 재동기화: $($reg.Count)개 가이드"

# ── 4) 푸시 ──
if($Push){
  Push-Location $root
  git add -A
  git commit -m "feat(site): $($s.name) 카드 + 설명서 추가" | Out-Null
  git push origin main
  Pop-Location
  Write-Host "푸시 완료 → Render 자동 재배포"
} else {
  Write-Host "미리보기 후 푸시하려면 -Push 옵션. (또는 git add -A; git commit; git push)"
}
