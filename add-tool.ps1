<#
.SYNOPSIS
  WAT 사이트에 새 툴 카드 + 설명서를 한 번에 추가한다.

.DESCRIPTION
  1) guide/_template.html 로 guide/<slug>.html 생성 (스펙 JSON 치환)
  2) index.html 의 해당 분류 섹션(<section class="tool-section" id="...">)의
     카드 그리드 끝에 새 카드 삽입 (CARD-INSERT 마커 없이 섹션 grid-close 앵커 기준)
  3) (-Push) git add/commit/push → Render 자동 재배포

  주의: index.html 카드 마크업은 현행 구조(article.card / badge-sq / chips / lnk)에
  맞춘다. more-tools(가이드 상호링크)는 현 사이트가 빈칸 컨벤션이라 채우지 않는다.

.EXAMPLE
  .\add-tool.ps1 -Spec .\_tool-spec.example.json
  .\add-tool.ps1 -Spec .\mytool.json -Push
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
function HtmlEnc($s){ [string]$s -replace '&','&amp;' -replace '<','&lt;' -replace '>','&gt;' }

# ── 분류별 고정값 (badge-sq 머리글자 = 분류 첫 글자) ──
$CAT = @{
  valuation = @{ label='평가';     ico='v'; icon='V'; hex='3182F6'; sec='valuation' }
  audit     = @{ label='감사보조'; ico='a'; icon='A'; hex='7C3AED'; sec='audit' }
  reference = @{ label='리서치';   ico='r'; icon='R'; hex='00C2B3'; sec='reference' }
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
function S($arr,$i){ if($arr -and $arr.Count -gt $i){ [string]$arr[$i] } else { '' } }   # who·prep = 문자열 배열
$map = @{
  '{{NAME}}'=$s.name; '{{EN}}'=$s.en; '{{TOOL_ID}}'=$s.tool_id;
  '{{CATEGORY}}'=$s.category; '{{CAT_LABEL}}'=$c.label;
  '{{ICO_CLASS}}'=$c.ico; '{{ICON}}'=$c.icon; '{{ICON_HEX}}'=$c.hex;
  '{{LEAD}}'=$s.lead;
  '{{WHO_1}}'=(S $s.who 0); '{{WHO_2}}'=(S $s.who 1); '{{WHO_3}}'=(S $s.who 2); '{{WHO_4}}'=(S $s.who 3);
  '{{CONCEPT_1_TITLE}}'=(J $s.concepts 0 't'); '{{CONCEPT_1_BODY}}'=(J $s.concepts 0 'b');
  '{{CONCEPT_2_TITLE}}'=(J $s.concepts 1 't'); '{{CONCEPT_2_BODY}}'=(J $s.concepts 1 'b');
  '{{PREP_1}}'=(S $s.prep 0); '{{PREP_2}}'=(S $s.prep 1); '{{PREP_3}}'=(S $s.prep 2);
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
  '{{MORE_TOOLS}}'=''   # 현 사이트 컨벤션: 빈칸
}
foreach($k in $map.Keys){ $tpl = $tpl.Replace($k, [string]$map[$k]) }
WriteUtf8 $guidePath $tpl
Write-Host "생성: guide/$($s.slug).html"

# ── 2) index.html 카드 삽입 (섹션 grid-close 앵커 기준) ──
# 현행 카드 마크업: article.card > card-top(badge-sq + card-tag) / h3 / p / chips / card-links.
$chips = ($s.feats | ForEach-Object { "<span class=`"chip`">$(HtmlEnc $_)</span>" }) -join ''
$openUrl = "https://wat.taild5874c.ts.net/#tool=$($s.tool_id)"
$card = @"
      <article class="card" data-reveal data-step="3">
        <div class="card-top"><div class="badge-sq">$($c.icon)</div><div class="card-tag mono">$(HtmlEnc $s.en)</div></div>
        <div><h3>$(HtmlEnc $s.name)</h3></div>
        <p>$(HtmlEnc $s.desc)</p>
        <div class="chips">$chips</div>
        <div class="card-links">
          <a class="lnk" href="guide/$($s.slug).html" target="_blank" rel="noopener">설명서 보기</a>
          <a class="lnk go" href="$openUrl" target="_blank" rel="noopener">도구 열기 <span class="arr">&#8594;</span></a>
        </div>
      </article>
"@
$card = $card.Replace("`r`n","`n").TrimEnd("`n")

$indexPath = Join-Path $root 'index.html'
$idx = ReadAll $indexPath
$nl = if($idx -match "`r`n"){ "`r`n" } else { "`n" }   # 파일 개행 스타일 보존

# 해당 섹션 시작 이후 첫 grid-close 3연속("    </div>" + "  </div>" + "</section>") 앞에 삽입.
# 이 3줄 시퀀스는 tool-section 끝에서만 나타나 앵커로 안전(tool-head 내부 </div>와 구분).
$secStart = $idx.IndexOf("<section class=`"tool-section`" id=`"$($c.sec)`">")
if($secStart -lt 0){ throw "index.html에 섹션 없음: tool-section id=$($c.sec)" }
$closeRe = [regex]"(\r?\n    </div>\r?\n  </div>\r?\n</section>)"
$m = $closeRe.Match($idx, $secStart)
if(-not $m.Success){ throw "섹션 grid-close 앵커를 찾지 못함: id=$($c.sec)" }
$cardBlock = $nl + ($card -replace "`n", $nl)
$idx = $idx.Substring(0, $m.Index) + $cardBlock + $idx.Substring($m.Index)
WriteUtf8 $indexPath $idx
Write-Host "카드 삽입: [$($s.category)] $($s.name)"

# ── 3) 푸시 ──
if($Push){
  Push-Location $root
  git add -A
  git commit -m "feat(site): $($s.name) 카드 + 설명서 추가($($c.label))" | Out-Null
  git push origin main
  Pop-Location
  Write-Host "푸시 완료 → Render 자동 재배포"
} else {
  Write-Host "미리보기 후 푸시하려면 -Push 옵션. (또는 git add -A; git commit; git push)"
}
