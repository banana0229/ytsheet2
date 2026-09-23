############# フォーム・キャラクター #############
use strict;
#use warnings;
use utf8;
use open ":utf8";
use feature 'signatures';
no warnings 'experimental::signatures';

my $LOGIN_ID = $::LOGIN_ID;

### 読込前処理 #######################################################################################
require $set::lib_palette_sub;
### 各種データライブラリ読み込み --------------------------------------------------
require $set::data_syndrome;
my @awakens;
my @impulses;
push(@awakens , @$_[0]) foreach(@data::awakens);
push(@impulses, @$_[0]) foreach(@data::impulses);

### データ読み込み ###################################################################################
my ($data, $file, $message) = loadSheetData();
our %pc = %{ $data };

our $isNewSheet = isNewSheet();

### 出力準備 #########################################################################################
$message = applyMessageName($message, $pc{characterName} || $pc{aka} || '無題');

### 初期設定 --------------------------------------------------
if($isNewSheet){
  $pc{playerName} = (getPlayerName($LOGIN_ID))[0];
  $pc{protect} ||= $LOGIN_ID ? 'account' : 'password';
}

if($::mode eq 'edit' || ($::mode =~ /^(?:convert|copy)$/ && $pc{ver})){
  %pc = upgradeCharaData(\%pc);
  if($pc{updateMessage}){
    $message .= "<hr>" if $message;
    $message .= "<h2>アップデート通知</h2><dl>";
    foreach (sort keys %{$pc{updateMessage}}){
      $message .= '<dt>'.$_.'</dt><dd>'.$pc{updateMessage}{$_}.'</dd>';
    }
    $message .= "</dl><small>前回保存時のバージョン:$pc{lasttimever}</small>";
  }
}
elsif($::mode eq 'blanksheet'){
  $pc{group} = $set::group_default;

  $pc{history0Exp}   = 0;

  ($pc{effect1Type},$pc{effect1Name},$pc{effect1Lv},$pc{effect1Timing},$pc{effect1Skill},$pc{effect1Dfclty},$pc{effect1Target},$pc{effect1Range},$pc{effect1Encroach},$pc{effect1Restrict},$pc{effect1Note})
    = ('auto','復原',1,'自動','―','自動成功','自身','至近','參照效果','―','恢復並上升(LV)D點的HP與侵蝕值');
  ($pc{effect2Type},$pc{effect2Name},$pc{effect2Lv},$pc{effect2Timing},$pc{effect2Skill},$pc{effect2Dfclty},$pc{effect2Target},$pc{effect2Range},$pc{effect2Encroach},$pc{effect2Restrict},$pc{effect2Note})
    = ('auto','防衛',1,'自動','―','自動成功','場景','視界','0','―','非超越者臨時角色化');

  $pc{comboNum} = 1;
  $pc{combo1Condition1} = '100%前';
  $pc{combo1Condition2} = '100%以上';

  $pc{paletteUseBuff} = 1;

  %pc = applyCustomizedInitialValues(\%pc);
}

## 画像・セリフ位置
setDefaultImageStyle(\%pc);
setDefaultWordsPosition(\%pc);

## カラー
setDefaultColors(\%pc);

## その他
$pc{createType} ||= 'F';

$pc{skillRideNum} ||= 2;
$pc{skillArtNum}  ||= 2;
$pc{skillKnowNum} ||= 2;
$pc{skillInfoNum} ||= 2;
$pc{effectNum}  ||= 5;
$pc{magicNum}   ||= 2;
$pc{weaponNum}  ||= 1;
$pc{armorNum}   ||= 1;
$pc{itemNum}    ||= 2;
$pc{historyNum} ||= 3;

### 折り畳み判断 --------------------------------------------------
my %open;
foreach (
  'skillMelee','skillRanged','skillRC','skillNegotiate',
  'skillDodge','skillPercept','skillWill','skillProcure',
){
  if ($pc{$_}){ $open{skill} = 'open'; last; }
}
foreach (
    'skillRide','skillArt','skillKnow','skillInfo',
){
  foreach my $num (1..$pc{$_.'Num'}){
    if ($pc{$_.$num}){ $open{skill} = 'open'; last; }
  }
}
if(existsRowStrict "lifepath",'Origin','Experience','Encounter','Awaken','Impulse'){ $open{lifepath} = 'open'; }
if(existsRowStrict "insanity",'','Note'){ $open{insanity} = 'open'; }
foreach (1..7){ if(existsRowStrict "lois$_"  ,'Relation','Name'){ $open{lois  } = 'open'; last; } }
foreach (1..3){ if(existsRowStrict "memory$_",'Relation','Name'){ $open{memory} = 'open'; last; } }
foreach (3..$pc{effectNum}){ if(existsRow "effect$_",'Name','Lv' ){ $open{effect} = 'open'; last; } }
foreach (1..$pc{magicNum }){ if(existsRow "magic$_" ,'Name','Exp'){ $open{magic } = 'open'; last; } }
foreach (1..$pc{comboNum}) { if(existsRowStrict "combo$_" ,'Name','Combo'){ $open{combo } = 'open'; last; } }
foreach (1..$pc{weaponNum  }){ if(existsRow "weapon$_"  ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{armorNum   }){ if(existsRow "armor$_"   ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{vehiclesNum}){ if(existsRow "vehicles$_",'Name','Stock','Exp'){ $open{item} = 'open'; last; } }
foreach (1..$pc{itemNum    }){ if(existsRow "item$_"    ,'Name','Stock','Exp'){ $open{item} = 'open'; last; } }

if(exists $data::syndrome_status{$pc{syndrome1}}){
  $pc{sttSyn1Body} = $pc{sttSyn1Sense}  = $pc{sttSyn1Mind} = $pc{sttSyn1Social} = '';
}
if(exists $data::syndrome_status{$pc{syndrome2}}){
  $pc{sttSyn2Body} = $pc{sttSyn2Sense}  = $pc{sttSyn2Mind} = $pc{sttSyn2Social} = '';
}

### 改行処理 --------------------------------------------------
convertEscapedBrToNewlines(\%pc,
  qw/freeNote freeHistory chatPalette/,
  ( map { 'words'.$_ } '', 2 .. ($set::image_maxcount || 1) ),
  ( map { "combo${_}Note"   } 1..$pc{comboNum} ),
  ( map { "weapon${_}Note"  } 1..$pc{weaponNum} ),
  ( map { "armor${_}Note"   } 1..$pc{armorNum} ),
  ( map { "vehicle${_}Note" } 1..$pc{vehicleNum} ),
  ( map { "item${_}Note"    } 1..$pc{itemNum} ),
);

### コンボ欄用選択肢 --------------------------------------------------
my @setComboSkills = qw/― 近戰 射擊 RC 交涉 迴避 知覺 意志 籌備/;
foreach my $id ('Ride','Art','Know','Info'){
  foreach my $num (1 .. $pc{'skill'.$id.'Num'}){
    push(@setComboSkills, $pc{'skill'.$id.$num.'Name'}) if $pc{'skill'.$id.$num.'Name'};
  }
}
push(@setComboSkills, '參照解說');

my @setComboStatus = qw/DEF==>自動（與技能對應的能力值） LABEL=▼替換 肉體 感覺 精神 社會/;
### フォーム表示 #####################################################################################
print renderEditPageStart(
  title => (removeTags removeRuby unescapeTags ($pc{characterName} || qq|“$pc{aka}”|)),
);
print renderEditHeaderMenu(
  tabsHtml => <<~'HTML',
    <li onclick="sectionSelect('common');" class="sheet-main"><span>角色<span class="shorten">資料</span></span>
    <li onclick="sectionSelect('palette');" class="unit-setting"><span><span class="shorten">角色(</span>棋子<span class="shorten">)</span></span><span>設定</span>
  HTML
);
print qq|<aside class="message">$message</aside>| if $message;

print <<"HTML";
  <section id="section-common">
    @{[ renderProtectBlock() ]}
    @{[ renderVisibilityBlock() ]}
    <div class="box" id="group">
      <dl>
        <dt>群組
        <dd><select name="group">@{[ renderGroupOptions ]}</select>
        <dt>標籤
        <dd>@{[ input 'tags' ]}
      </dl>
    </div>

    <div class="box in-toc" id="name-form" data-content-title="キャラクター名・プレイヤー名">
      <div>
        <dl id="character-name">
          <dt>角色名稱
          <dd>@{[ input 'characterName','text',"setName",'id="main-name"' ]}
          <dt class="ruby">讀音
          <dd>@{[ input 'characterNameRuby','text',"setName" ]}
        </dl>
        <dl id="aka">
          <dt>代號
          <dd>@{[ input 'aka','text',"setName" ]}
          <dt class="ruby">讀音
          <dd>@{[ input 'akaRuby','text',"setName" ]}
        </dl>
      </div>
      <dl id="player-name">
        <dt>玩家
        <dd>@{[ input 'playerName' ]}
      </dl>
    </div>

    <details class="box" id="regulation" @{[$::mode eq 'edit' ? '':'open']}>
      <summary class="in-toc">創建條件</summary>
      <dl>
        <dt>創建方式
        <dd>@{[ radios 'createType', 'changeCreateType', 'C=>基本創建','F=>完全描繪' ]}
        <dt>消費經驗點
        <dd>@{[ input "history0Exp",'number','changeRegu',($set::make_fix?' readonly':'') ]} <span class="fullscratch-only">※完全描繪的130點不包含在內。</span>
        <dt>舞台
        <dd>@{[ input "stage",'','checkStage','list="list-stage"' ]}<br>
          ※舞台名稱如果<b>包含<b>「クロウリングケイオス」的話，會出現舞台的專用項目。
        <dt>備註
        <dd>@{[ input "history0Note" ]}
      </dl>
    </details>

    <div id="area-status">
      @{[ renderImageForm() ]}

      <div class="box-union" id="personal">
        <dl class="box"><dt>年齡  <dd>@{[input "age"]}</dl>
        <dl class="box"><dt>性別  <dd>@{[input "gender",'','','list="list-gender"']}</dl>
        <dl class="box"><dt>星座  <dd>@{[input "sign",'','','list="list-sign"']}</dl>
        <dl class="box"><dt>身高  <dd>@{[input "height"]}</dl>
        <dl class="box"><dt>體重  <dd>@{[input "weight"]}</dl>
        <dl class="box"><dt>血型<dd>@{[input "blood",'','','list="list-blood"']}</dl>
      </div>
      <div class="box-union" id="works-cover">
        <dl class="box"><dt>真身<dd>@{[input "works",'','checkWorks']}</dl>
        <dl class="box"><dt>表面<dd>@{[input "cover"]}</dl>
      </div>

      <div class="box" id="syndrome-status">
        <h2 class="in-toc" data-content-title="症候群／能力值">症候群／能力值 [<span id="exp-status">0</span>]</h2>
        <table>
          <thead>
            <tr>
              <th class="breed"><span class="small">血統<span>
              <th>症候群
              <th>肉體
              <th>感覺
              <th>精神
              <th>社會
          <tbody class="syndrome-rows">
            <tr>
              <th class="breed" rowspan="3"><span id="breed-value"></span><span class="small">種</span>
              <td>@{[ selectInput 'syndrome1','changeSyndrome(1,this.value)',@data::syndromes ]}
              <td><span id="stt-syn1-body"  ></span>@{[ input "sttSyn1Body"  ,'number','calcStt' ]}
              <td><span id="stt-syn1-sense" ></span>@{[ input "sttSyn1Sense" ,'number','calcStt' ]}
              <td><span id="stt-syn1-mind"  ></span>@{[ input "sttSyn1Mind"  ,'number','calcStt' ]}
              <td><span id="stt-syn1-social"></span>@{[ input "sttSyn1Social",'number','calcStt' ]}
            <tr>
              <td>@{[ selectInput 'syndrome2','changeSyndrome(2,this.value)',@data::syndromes ]}
              <td><span id="stt-syn2-body"  ></span>@{[ input "sttSyn2Body"  ,'number','calcStt' ]}
              <td><span id="stt-syn2-sense" ></span>@{[ input "sttSyn2Sense" ,'number','calcStt' ]}
              <td><span id="stt-syn2-mind"  ></span>@{[ input "sttSyn2Mind"  ,'number','calcStt' ]}
              <td><span id="stt-syn2-social"></span>@{[ input "sttSyn2Social",'number','calcStt' ]}
            <tr>
              <td>@{[ selectInput 'syndrome3','changeSyndrome(3,this.value)',@data::syndromes ]}
              <td colspan="4">
          <tbody>
            <tr class="works-row">
              <th colspan="2" class="right">真身修正
              <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'body'  , '+1' ]}
              <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'sense' , '+1' ]}
              <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'mind'  , '+1' ]}
              <td>@{[ radio 'sttWorks', 'deselectable,calcStt', 'social', '+1' ]}
            <tr>
              <th colspan="2" class="right"><span class="construction-only">任意分配＋</span>成長
              <td>@{[input "sttGrowBody"  ,'number','calcStt', 'min="0"']}
              <td>@{[input "sttGrowSense" ,'number','calcStt', 'min="0"']}
              <td>@{[input "sttGrowMind"  ,'number','calcStt', 'min="0"']}
              <td>@{[input "sttGrowSocial",'number','calcStt', 'min="0"']}
            <tr>
              <th colspan="2" class="right">其他修正
              <td>@{[input "sttAddBody"  ,'number','calcStt']}
              <td>@{[input "sttAddSense" ,'number','calcStt']}
              <td>@{[input "sttAddMind"  ,'number','calcStt']}
              <td>@{[input "sttAddSocial",'number','calcStt']}
            <tr>
              <th colspan="2" class="right">總計
              <td id="stt-total-body"  >0
              <td id="stt-total-sense" >0
              <td id="stt-total-mind"  >0
              <td id="stt-total-social">0
            </tr>
          </tbody>
        </table>
      </div>
      <div class="box-union" id="sub-status">
        <dl class="box" id="max-hp">
          <dt>HP最大值
          <dd>+@{[input "maxHpAdd",'number','calcMaxHp']}=<b id="max-hp-total"></b>
        </dl>
        <dl class="box" id="stock-pt">
          <dt>常備化點數
          <dd>+@{[input "stockAdd",'number','calcStock']}=<b id="stock-total"></b>
        </dl>
        <dl class="box" id="saving">
          <dt>財產點數
          <dd>+@{[input "savingAdd",'number','calcSaving']}=<b id="saving-total"></b>
        </dl>
        <dl class="box" id="initiative">
          <dt>行動值
          <dd>+@{[input "initiativeAdd",'number','calcInitiative']}=<b id="initiative-total"></b>
        </dl>
        <dl class="box" id="move">
          <dt>戰鬥移動
          <dd>+@{[input "moveAdd",'number','calcMove']}=<b id="move-total"></b>
        </dl>
        <dl class="box" id="dash">
          <dt>全力移動
          <dd><b id="dash-total"></b>
        </dl>
        <dl class="box crc-only" id="magic-dice">
          <dt>魔術骰
          <dd>+@{[input "magicAdd",'number','calcMagicDice']}=<b id="magic-total"></b>
        </dl>
      </div>
    </div>

    <details class="box" id="status" $open{skill}>
      <summary class="in-toc" data-content-title="技能">技能 [<span id="exp-skill">0</span>]</summary>
      <dl id="status-table">
        <dt>肉體<dd id="skill-body"  >0
        <dt>感覺<dd id="skill-sense" >0
        <dt>精神<dd id="skill-mind"  >0
        <dt>社會<dd id="skill-social">0
      </dl>
      <dl id="skill-table">
        <dt>【肉體】を使用する技能
        <dd>
          <dl id="skill-body-table">
            <dt class="left">近戰<dd>@{[input "skillMelee"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddMelee"  ,'number','calcSkill']}
            <dt class="left">迴避<dd>@{[input "skillDodge"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddDodge"  ,'number','calcSkill']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillRide${num}Name",'','comboSkillSetAll','list="list-ride"')
              . '<dd>'. (input "skillRide${num}",'number','calcSkill', 'min="0"')
              . '+'. (input "skillAddRide${num}",'number','calcSkill')
            } 1 .. $pc{skillRideNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Ride'|, 'skillRideNum') ]}
        </dd>
        <dt>【感覺】を使用する技能
        <dd>
          <dl id="skill-sense-table">
            <dt class="left">射擊<dd>@{[input "skillRanged" ,'number','calcSkill', 'min="0"']}+@{[input "skillAddRanged"    ,'number','calcSkill']}
            <dt class="left">知覺<dd>@{[input "skillPercept",'number','calcSkill', 'min="0"']}+@{[input "skillAddPercept",'number','calcSkill']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillArt${num}Name",'','comboSkillSetAll','list="list-art"')
              . '<dd>'. (input "skillArt${num}",'number','calcSkill', 'min="0"')
              . '+'. (input "skillAddArt${num}",'number','calcSkill')
            } 1 .. $pc{skillArtNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Art'|, 'skillArtNum') ]}
        </dd>
        <dt>【精神】を使用する技能
        <dd>
          <dl id="skill-mind-table">
            <dt class="left">ＲＣ<dd>@{[input "skillRC"  ,'number','calcSkill', 'min="0"']}+@{[input "skillAddRC"  ,'number','calcSkill']}
            <dt class="left">意志<dd>@{[input "skillWill",'number','calcSkill', 'min="0"']}+@{[input "skillAddWill",'number','calcSkill']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillKnow${num}Name",'','comboSkillSetAll','list="list-know"')
              . '<dd>'. (input "skillKnow${num}",'number','calcSkill', 'min="0"')
              . '+'. (input "skillAddKnow${num}",'number','calcSkill')
            } 1 .. $pc{skillKnowNum} ]}
          </dl>
        @{[ renderAddDelButtons('skill', q|'Know'|, 'skillKnowNum') ]}
        </dd>
        <dt>【社會】を使用する技能
        <dd>
          <dl id="skill-social-table">
            <dt class="left">交涉<dd>@{[input "skillNegotiate",'number','calcSkill', 'min="0"']}+@{[input "skillAddNegotiate",'number']}
            <dt class="left">籌備<dd>@{[input "skillProcure"  ,'number','calcSkill();calcStock', 'min="0"']}+@{[input "skillAddProcure",  'number','calcSkill();calcStock']}
            @{[ map {
              my $num = $_;
              '<dt>'. (input "skillInfo${num}Name",'','comboSkillSetAll','list="list-info"')
              . '<dd>'. (input "skillInfo${num}",'number','calcSkill', 'min="0"')
              . '+'. (input "skillAddInfo${num}",'number','calcSkill')
            } 1 .. $pc{skillInfoNum} ]}
          </dl>
          @{[ renderAddDelButtons('skill', q|'Info'|, 'skillInfoNum') ]}
        </dd>
      </dl>
      <ul class="annotate">
        <li>右側的輸入框是D露易絲等額外加值的欄位（不計算經驗點）
        <li>沒輸入真身的對應技能時<span class="fullscratch-only">消費經驗點會顯示為「-9」</span><span class="construction-only">任意技能分配會顯示為「-4.5」</span><br>
          正確輸入真身的對應技能時會變成「0」點（部分擴充收錄的真身例外）
      </ul>
    </details>
    <details class="box" id="lifepath" $open{lifepath}>
      <summary class="in-toc">經歷</summary>
      <table class="edit-table line-tbody">
        <tbody>
          <tr>
            <th>出身
            <td colspan="2">@{[ input "lifepathOrigin"]}
            <td colspan="2" class="left">@{[ input "lifepathOriginNote",'','','placeholder="備註"' ]}
        <tbody>
          <tr>
            <th>經驗
            <td colspan="2">@{[ input "lifepathExperience"]}
            <td colspan="2" class="left">@{[ input "lifepathExperienceNote",'','','placeholder="備註"' ]}
        <tbody>
          <tr>
            <th id="encounter-or-desire">邂逅/欲望
            <td colspan="2">@{[ input "lifepathEncounter"]}
            <td colspan="2" class="left">@{[ input "lifepathEncounterNote",'','','placeholder="備註"' ]}
        <tbody class="awaken">
          <tr>
            <th>覺醒
            <td><select name="lifepathAwaken" oninput="calcEncroach()">@{[ option "lifepathAwaken",@awakens ]}</select>
            <th class="small encroach">侵蝕值
            <td class="center encroach" id="awaken-encroach">
            <td class="left">@{[ input "lifepathAwakenNote",'','','placeholder="備註"' ]}
        <tbody class="impulse">
          <tr>
            <th rowspan="2">衝動
            <td><select name="lifepathImpulse" oninput="refreshByImpulse()">@{[ option "lifepathImpulse",@impulses ]}</select>
            <th class="small encroach">侵蝕值
            <td class="center encroach" id="impulse-encroach">
            <td class="left">@{[ input "lifepathImpulseNote",'','','placeholder="備註"' ]}
          <tr>
            <th><span class="small">@{[ input "lifepathUrgeCheck",'checkbox' ]}變異暴走</span>
            <th class="small">效果
            <td class="left" colspan="2">@{[ input "lifepathUrgeNote",'','','placeholder="效果"' ]}
        <tbody class="encroach-offset">
          <tr>
            <th colspan="3" class="right small">其他修正
            <td class="center">@{[ input "lifepathOtherEncroach",'number','calcEncroach' ]}
            <td class="left">@{[ input "lifepathOtherNote",'','','placeholder="備註"' ]}
        <tbody class="neutral-encroach">
          <tr>
            <th colspan="3" class="right">侵蝕率<span class="suffix">基本值</span>
            <td class="center bold">
              <span class="calculated-value" id="base-encroach"></span>
              @{[ input "encroachFixedValue", 'number', 'calcEncroach' ]}
            <td>@{[ checkbox 'encroachFixed', '固定侵蝕率（ＮＰＣ用）', 'encroachModeChanged' ]}
        </tbody>
      </table>
    </details>
    <div id="enc-bonus" style="position: relative;">
      <div class="box">
        <h2 class="in-toc">侵蝕率效果表</h2>
        <p>
          <!-- 現在侵蝕率:@{[ input 'currentEncroach','number','encroachBonusSet(this.value)','style="width: 4em;"' ]} -->
          @{[ checkbox 'encroachEaOn','套用EA','encroachBonusType' ]}
        </p>
        <table class="data-table" id="enc-table">
          <colgroup></colgroup>
          <tr id="enc-table-head">
          <tr id="enc-table-dices">
          <tr id="enc-table-level">
        </table>
      </div>
    </div>
    <details class="box" id="lois" $open{lois} style="position:relative">
      <summary class="in-toc">露易絲</summary>
      <div>
        <table class="edit-table no-border-cells" id="lois-table">
          <colgroup>
          <col class="relation">
          <col class="name">
          <col class="emo">
          <col class="slash">
          <col class="emo">
          <col class="color">
          <col class="note">
          <col class="sperior">
          <col class="state">
          </colgroup>
          <thead>
            <tr>
              <th>關係
              <th>名稱
              <th colspan="3">感情<span class="small">(Positive／Negative)</span>
              <th>屬性
              <th colspan="2" class="right small">S露易絲
              <th class="right">狀態
            </tr>
          <tbody>
            @{[ map {
              my $num = $_;
              $pc{"lois${num}State"} = '露易絲' unless $pc{"lois${num}State"};
              <<~"ROW";
              <tr id="lois${num}">
                <td class="relation"><span class="handle"></span>@{[input "lois${num}Relation",'','','list="list-lois-relation"']}
                <td class="name    ">@{[input "lois${num}Name",'','encroachBonusType']}
                <td class="emo     ">@{[input "lois${num}EmoPosiCheck",'checkbox',"emoP($num)"]}@{[input "lois${num}EmoPosi",'','','list="list-emotionP"']}
                <td class="slash   ">／
                <td class="emo     ">@{[input "lois${num}EmoNegaCheck",'checkbox',"emoN($num)"]}@{[input "lois${num}EmoNega",'','','list="list-emotionN"']}
                <td class="color   ">@{[input "lois${num}Color",'',"changeLoisColor($num)",'list="list-lois-color"']}
                <td class="note    ">@{[input "lois${num}Note"]}
                <td class="sperior ">@{[input "lois${num}S",'checkbox',"sLois($num)"]}
                <td class="state   " onclick="changeLoisState(this.parentNode.id)"><span id="lois${num}-state" data-state="$pc{"lois${num}State"}"></span>@{[input "lois${num}State",'hidden']}
              ROW
            } 1 .. 7 ]}
          </tbody>
        </table>
      </div>
      <div class="right lois-reset-buttons">
        <button type="button" class="small" onclick="resetLoisAll()">清空所有露易絲</button>
        <button type="button" class="small" onclick="resetLoisAdd()">清空第4格以後的路易斯</button>
      </div>
    </details>
    <details class="box" id="memory" $open{memory}>
      <summary class="in-toc" data-content-title="回憶">回憶 [<span id="exp-memory">0</span>]</summary>
      <div>
        <table class="edit-table no-border-cells" id="memory-table">
          <thead>
            <tr>
              <th>
              <th>關係
              <th>名稱
              <th>感情
              <th>
            </tr>
          <tbody>
            @{[ map {
              my $num = $_;
              <<~"ROW";
              <tr id="memory${num}">
                <td><span class="handle"></span>
                <td>@{[input "memory${num}Relation",'','calcMemory']}
                <td>@{[input "memory${num}Name",'','calcMemory']}
                <td>@{[input "memory${num}Emo"]}
                <td>@{[input "memory${num}Note"]}
              ROW
            } 1 .. 3 ]}
          </tbody>
        </table>
      </div>
      <ul class="annotate"><li>有輸入「關係」或「名稱」才會計算經驗點。</ul>
    </details>
    <details class="box crc-only" id="insanity" $open{insanity}>
      <summary class="in-toc">永久瘋狂</summary>
      <dl class="edit-table " id="insanity-table">
        <dt>@{[input "insanity",'','','placeholder="名稱"']}
        <dd>@{[input "insanityNote",'','','placeholder="效果"']}
      </dl>
    </details>

    <details class="box" id="effect" $open{effect}>
      <summary class="in-toc" data-content-title="異能">異能 [<span id="exp-effect">0</span>]</summary>
      <div>
        <table class="edit-table line-tbody no-border-cells" id="effect-table">
          <thead id="effect-head">
            <tr><th><th>名稱<th>LV<th>時機<th>技能<th>難易度<th>對象<th>射程<th>侵蝕值<th>限制
          @{[ renderTemplateLoop(
            'effect',
            sub ($num) {
              return <<~"ROW";
              <tbody id="effect-row${num}">
                <tr>
                  <td rowspan="2" class="handle">
                  <td>@{[input "effect${num}Name",'','','placeholder="名稱"']}
                  <td>@{[input "effect${num}Lv",'number','calcEffect','placeholder="Lv" min="0"']}
                  <td>@{[input "effect${num}Timing",'','','placeholder="時機" list="list-timing"']}
                  <td>@{[input "effect${num}Skill",'','','placeholder="技能" list="list-effect-skill"']}
                  <td>@{[input "effect${num}Dfclty",'','','placeholder="難易度" list="list-dfclty"']}
                  <td>@{[input "effect${num}Target",'','','placeholder="對象" list="list-target"']}
                  <td>@{[input "effect${num}Range",'','','placeholder="射程" list="list-range"']}
                  <td>@{[input "effect${num}Encroach",'','','placeholder="侵蝕值" list="list-encroach"']}
                  <td>@{[input "effect${num}Restrict",'','','placeholder="限制" list="list-restrict"']}
                <tr><td colspan="9">
                  <div>
                    <b>種類</b><select name="effect${num}Type" oninput="calcEffect()">@{[ option "effect${num}Type",'auto=>自動取得','dlois=>D露易絲','easy=>簡易','enemy=>敵用' ]}</select>
                    <b class="small">經驗點修正</b>@{[input "effect${num}Exp",'number','calcEffect']}
                    <b>效果</b>@{[input "effect${num}Note"]}
                  </div>
              ROW
            }
          ) ]}
          <tfoot id="effect-foot">
            <tr><th><th>名稱<th>LV<th>時機<th>技能<th>難易度<th>對象<th>射程<th>侵蝕值<th>限制
        </table>
      </div>
      @{[ renderAddDelButtons('effect') ]}
      <ul class="annotate">
        <li>種類設定為「自動取得」或「D露易絲」時，取得時(LV1)的經驗點將以0點做計算。
        <li>經驗點修正的欄位，可用來處理自動計算無法對應的例外狀況(如D露易絲轉生者)。
      </ul>
    </details>
    <div class="box trash-box" id="effect-trash">
      <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除エフェクト</span></h2>
      <table class="edit-table line-tbody" id="effect-trash-table"></table>
      <i class="material-symbols-outlined close-button" onclick="document.getElementById('effect-trash').style.display = 'none';">close</i>
    </div>

    <details class="box crc-only" id="magic" $open{magic}>
      <summary class="in-toc" data-content-title="術式">術式 [<span id="exp-magic">0</span>]</summary>
      <div>
        <table class="edit-table line-tbody no-border-cells" id="magic-table">
          <thead id="magic-head">
            <tr><th><th>名稱<th>種類<th>經驗點<th>發動值<th>侵蝕值<th>效果
          @{[ renderTemplateLoop(
            'magic',
            sub ($num) {
              return <<~"ROW";
              <tbody id="magic-row${num}">
                <tr>
                  <td class="handle">
                  <td>@{[input "magic${num}Name"    ,'','','placeholder="名稱"']}
                  <td>@{[input "magic${num}Type"    ,'','','placeholder="種類" list="list-magic-type"']}
                  <td>@{[input "magic${num}Exp"     ,'number','calcMagic']}
                  <td>@{[input "magic${num}Activate",'','','placeholder="發動值"']}
                  <td>@{[input "magic${num}Encroach",'','','placeholder="侵蝕值"']}
                  <td>@{[input "magic${num}Note"    ,'','','placeholder="效果"']}
              ROW
            }
          ) ]}
        </table>
      </div>
      @{[ renderAddDelButtons('magic') ]}
    </details>
    <div class="box trash-box" id="magic-trash">
      <h2><span class="material-symbols-outlined">delete</span><span class="shorten">削除術式</span></h2>
      <table class="edit-table line-tbody" id="magic-trash-table"></table>
      <i class="material-symbols-outlined close-button" onclick="document.getElementById('magic-trash').style.display = 'none';">close</i>
    </div>

    <details class="box" id="combo" $open{combo} style="position:relative">
      <summary class="in-toc">組合</summary>
      <div id="combo-list">
        @{[ renderTemplateLoop(
          'combo',
          sub ($num) {
            return <<~"ROW";
            <div class="combo-table" id="combo-row${num}">
              <div class="handle"></div>
              <dl class="combo-name"><dt>名稱</dt><dd>@{[input "combo${num}Name"]}</dd></dl>
              <dl class="combo-combo"><dt>組合內容</dt><dd>@{[input "combo${num}Combo"]}</dl>
              <div class="combo-in">
                <dl><dt>時機<dd>@{[input "combo${num}Timing",'','','list="list-combo-timing"']}</dl>
                <dl><dt>技能      <dd>@{[ selectBox "combo${num}Skill", "calcCombo(${num})", @setComboSkills ]}</dl>
                <dl><dt>能力值    <dd>@{[ selectBox "combo${num}Stt", "calcCombo(${num})", @setComboStatus ]}</dl>
                <dl><dt>難易度    <dd>@{[input "combo${num}Dfclty",'','','list="list-dfclty"']}</dl>
                <dl><dt>對象      <dd>@{[input "combo${num}Target",'','','list="list-target"']}</dl>
                <dl><dt>射程      <dd>@{[input "combo${num}Range",'','','list="list-range"']}</dl>
                <dl><dt>侵蝕值    <dd>@{[input "combo${num}Encroach"]}</dl>
              </div>
              <dl class="combo-out">
                <dt class="combo-cond">條件<span class="combo-condition-utility"></span>
                <dt class="combo-dice">骰數
                <dt class="combo-crit">Ｃ值
                <dt class="combo-fixed">達成值修正<br><span class="very-small">(技能等級+修正值)</span>
                <dt class="combo-atk">攻擊力
                @{[ map {
                  <<~"DD";
                  <dd>@{[input "combo${num}Condition${_}"]}
                  <dd id="combo${num}Stt${_}"></dd>
                  <dd>@{[input "combo${num}DiceAdd${_}"]}
                  <dd>@{[input "combo${num}Crit${_}"]}
                  <dd id="combo${num}SkillLv${_}"></dd>
                  <dd>@{[input "combo${num}FixedAdd${_}"]}
                  <dd>@{[input "combo${num}Atk${_}"]}
                  DD
                } 1 .. 5 ]}
              </dl>
              <div class="combo-note"><textarea name="combo${num}Note" rows="3" placeholder="解說">$pc{"combo${num}Note"}</textarea></div>
              <div class="combo-other">@{[ checkbox "combo${num}Manual",'不自動代入技能等級與能力值',"calcCombo(${num})" ]} <span class="button" onclick="addCombo($num)">複製組合</span></div>
            </div>
            ROW
          }
        ) ]}
      </div>
      @{[ renderAddDelButtons('combo') ]}
    </details>

    <details class="box box-union" id="items" $open{item}>
    <summary class="in-toc" data-content-title="道具">道具 [<span id="exp-item">0</span>]</summary>
    <div class="box">
      <table class="edit-table no-border-cells" id="weapon-table">
        <thead>
          <tr><th>武器<th>常備化<th>經驗點<th>種類<th>技能<th>命中<th>攻擊力<th><span class="small">格擋值</span><th>射程<th>解說
        <tbody>
          @{[ renderTemplateLoop(
            'weapon',
            sub ($num) {
              return <<~"ROW";
              <tr id="weapon-row${num}">
                <td>@{[input "weapon${num}Name"]}<span class="handle"></span>
                <td>@{[input "weapon${num}Stock",'number','calcItem', 'min="0"']}
                <td>@{[input "weapon${num}Exp",'number','calcItem', 'min="0"']}
                <td>@{[input "weapon${num}Type",'','','list="list-weapon-type"']}
                <td>@{[input "weapon${num}Skill",'','','list="list-weapon-skill"']}
                <td>@{[input "weapon${num}Acc"]}
                <td>@{[input "weapon${num}Atk"]}
                <td>@{[input "weapon${num}Guard"]}
                <td>@{[input "weapon${num}Range"]}
                <td><textarea name="weapon${num}Note" rows="2">$pc{"weapon${num}Note"}</textarea>
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('weapon') ]}
    </div>
    <div class="box">
      <table class="edit-table no-border-cells" id="armor-table">
        <thead>
          <tr><th>防具<th>常備化<th>經驗點<th>種類<th><th>行動<th>閃躲<th>裝甲值<th>解說
        <tbody>
          @{[ renderTemplateLoop(
            'armor',
            sub ($num) {
              return <<~"ROW";
              <tr id="armor-row${num}">
                <td>@{[input "armor${num}Name"]}<span class="handle"></span>
                <td>@{[input "armor${num}Stock",'number','calcItem', 'min="0"']}
                <td>@{[input "armor${num}Exp",'number','calcItem', 'min="0"']}
                <td>@{[input "armor${num}Type",'','','list="list-armor-type"']}
                <td>
                <td>@{[input "armor${num}Initiative"]}
                <td>@{[input "armor${num}Dodge"]}
                <td>@{[input "armor${num}Armor"]}
                <td><textarea name="armor${num}Note" rows="2">$pc{"armor${num}Note"}</textarea>
              ROW
            }
          ) ]}
        </tbody>
      </table>
      @{[ renderAddDelButtons('armor') ]}
    </div>
    <div class="box">
      <table class="edit-table no-border-cells" id="vehicle-table">
        <thead>
          <tr><th>載具<th>常備化<th>經驗點<th>種類<th>技能<th>行動<th>攻擊力<th>装甲值<th><span class="small">全力移動</span><th>解說
        <tbody>
          @{[ renderTemplateLoop(
            'vehicle',
            sub ($num) {
              return <<~"ROW";
              <tr id="vehicle-row${num}">
                <td>@{[input "vehicle${num}Name"]}<span class="handle"></span>
                <td>@{[input "vehicle${num}Stock",'number','calcItem', 'min="0"']}
                <td>@{[input "vehicle${num}Exp",'number','calcItem', 'min="0"']}
                <td>@{[input "vehicle${num}Type",'','','list="list-vehicle-type"']}
                <td>@{[input "vehicle${num}Skill",'','','list="list-vehicle-skill"']}
                <td>@{[input "vehicle${num}Initiative"]}
                <td>@{[input "vehicle${num}Atk"]}
                <td>@{[input "vehicle${num}Armor"]}
                <td>@{[input "vehicle${num}Dash"]}
                <td><textarea name="vehicle${num}Note" rows="2">$pc{"vehicle${num}Note"}</textarea>
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('vehicle') ]}
    </div>
    <div class="box">
      <table class="edit-table no-border-cells" id="item-table">
        <thead>
          <tr><th>一般道具<th>常備化<th>經驗點<th>種類<th>技能<th>解說
        <tbody>
          @{[ renderTemplateLoop(
            'item',
            sub ($num) {
              return <<~"ROW";
              <tr id="item-row${num}">
                <td>@{[input "item${num}Name"]}<span class="handle"></span>
                <td>@{[input "item${num}Stock",'number','calcItem', 'min="0"']}
                <td>@{[input "item${num}Exp",'number','calcItem', 'min="0"']}
                <td>@{[input "item${num}Type",'','','list="list-item-type"']}
                <td>@{[input "item${num}Skill",'','','list="list-item-skill"']}
                <td><textarea name="item${num}Note" rows="2">$pc{"item${num}Note"}</textarea>
              ROW
            }
          ) ]}
      </table>
      @{[ renderAddDelButtons('item') ]}
    </div>
    <div class="box">
      <table class="edit-table">
        <thead><tr><th><th>常備化<th>經驗點<th>
        <tbody>
          <tr>
            <th>合計
            <td><b id="item-total-stock">0</b><wbr>/<b id="item-max-stock">0</b>
            <td class="bold" id="item-total-exp">0
            <td>
          </tr>
        </tbody>
      </table>
    </div>
    </details>

    <details class="box" id="free-note" @{[$pc{freeNote}?'open':'']}>
      <summary class="in-toc">外貌・經歷・筆記</summary>
      <textarea name="freeNote">$pc{freeNote}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeNote\')">最新のメモを適用する</button>' : '' ]}
    </details>

    <details class="box" id="free-history" @{[$pc{freeHistory}?'open':'']}>
      <summary class="in-toc">履歷（自由填寫）</summary>
      <textarea name="freeHistory">$pc{freeHistory}</textarea>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestSingleData(\'freeHistory\')">最新の履歴（自由記入）を適用する</button>' : '' ]}
    </details>

    <div class="box" id="history">
      <h2 class="in-toc">團務履歷</h2>
      <table class="edit-table line-tbody no-border-cells" id="history-table">
        <colgroup id="history-col">
          <col>
          <col class="date  ">
          <col class="title ">
          <col class="exp   ">
          <col class="apply ">
          <col class="gm    ">
          <col class="member">
        </colgroup>
        <thead id="history-head">
          <tr>
            <th>
            <th>日期
            <th>名稱
            <th colspan="2">經驗點
            <th>GM
            <th>参加者
          <tr>
            <td>-
            <td>
            <td>角色創建
            <td id="history0-exp">$pc{history0Exp}
            <td><input type="checkbox" checked disabled>套用
        @{[ renderTemplateLoop(
          'history',
          sub ($num) {
            return <<~"ROW";
            <tbody id="history-row${num}">
              <tr>
                <td class="handle" rowspan="2">
                <td class="date  " rowspan="2">@{[input "history${num}Date" ]}
                <td class="title " rowspan="2">@{[input "history${num}Title" ]}
                <td class="exp   ">@{[ input "history${num}Exp",'text','calcExp' ]}
                <td class="apply "><label>@{[ input "history${num}ExpApply",'checkbox','calcExp' ]}<b>套用</b></label>
                <td class="gm    ">@{[ input "history${num}Gm" ]}
                <td class="member">@{[ input "history${num}Member" ]}
              <tr>
                <td colspan="4" class="left">@{[ input "history${num}Note",'','','placeholder="備註"' ]}
            ROW
          }
        ) ]}
        <tfoot id="history-foot">
          <tr><th></th><th>日期</th><th>名稱</th><th colspan="2">經驗點</th><th>GM</th><th>参加者</th></tr>
      </table>
      @{[ renderAddDelButtons('history') ]}
      <h2>填寫範例</h2>
      <table class="example edit-table line-tbody no-border-cells">
        <colgroup>
          <col>
          <col class="date  ">
          <col class="title ">
          <col class="exp   ">
          <col class="apply ">
          <col class="gm    ">
          <col class="member">
        </colgroup>
        <thead>
          <tr>
            <th>
            <th>日期
            <th>名稱
            <th colspan="2">經驗點
            <th>GM
            <th>参加者
          </tr>
        <tbody>
          <tr>
            <td>-
            <td><input type="text" value="2020-03-18" disabled>
            <td><input type="text" value="第一話「填寫範例」" disabled>
            <td><input type="text" value="10+5+1" disabled>
            <td><label><input type="checkbox" checked disabled><b>套用</b></label>
            <td class="gm"><input type="text" value="サンプルGM" disabled>
            <td class="member"><input type="text" value="荒川ヨドミ　鎧畑ショウコ　橘シドウ　金床スズ" disabled>
          </tr>
        </tbody>
      </table>
      <ul class="annotate">
        <li>經驗點的欄位可以進行<code>10+5+1</code>的四則運算（可以用來區分不同條件的經驗點）。<br>
          勾選經驗點欄右邊的套用後，就會計算那欄的經驗點。
      </ul>
      @{[ ($::in{log} || $::in{overwrite}) ? '<button type="button" class="set-newest" onclick="setNewestHistoryData()">最新の團務履歷を適用する</button>' : '' ]}
    </div>

    <div class="box" id="exp-footer">
      <p class="construction-only">
        <b>基本創建</b>
        :  任意能力值分配[<b id="freepoint-status"></b>/3]
        ／ 任意技能分配[<b id="freepoint-skill"></b>/5]
        ／ 任意異能[<b id="freepoint-effect"></b>/4]個
        ／ 任意異能升級分配[<b id="freepoint-effectlv"></b>/2]
      </p>
      <p>
      經驗點[<b id="exp-total"></b>] -
      ( 能力值[<b id="exp-used-status"></b>]
      + 技能[<b id="exp-used-skill"></b>]
      + 異能[<b id="exp-used-effect"></b>]
      <span class="crc-only">+ 術式[<b id="exp-used-magic"></b>]</span>
      + 道具[<b id="exp-used-item"></b>]
      + 回憶[<b id="exp-used-memory"></b>]
      ) = 剩餘[<b id="exp-rest"></b>]点
      </p>
    </div>
  </section>
HTML
print renderChatPaletteForm();

print renderEditPageEnd(
  notes => '©FarEast Amusement Research Co.,Ltd.「ダブルクロスThe 3rd Edition」',
  extraHtml => renderDataList() . renderFooterScript(),
);

sub renderDataList {
  return <<~"HTML";
  <datalist id="list-stage">
    <option value="基本ステージ">
    <option value="基本ステージ(UA)">
    <option value="オーヴァードアカデミア">
    <option value="ナイトメアプリズン">
    <option value="デモンズシティ">
    <option value="陽炎の戦場">
    <option value="エンドライン">
    <option value="ホーリーグレイル">
    <option value="平安京物怪録">
    <option value="モダンタイムス">
    <option value="エピックヒーローズ">
    <option value="クロノスガーディアン">
    <option value="レネゲイドウォー">
    <option value="バッドシティ">
    <option value="ウィアードエイジ">
    <option value="カオスガーデン">
    <option value="クロウリングケイオス">
  </datalist>
  <datalist id="list-gender">
    <option value="男">
    <option value="女">
    <option value="其他">
    <option value="無">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-sign">
    <option value="牡羊座">
    <option value="金牛座">
    <option value="雙子座">
    <option value="巨蟹座">
    <option value="獅子座">
    <option value="處女座">
    <option value="天秤座">
    <option value="天蠍座">
    <option value="射手座">
    <option value="摩羯座">
    <option value="水瓶座">
    <option value="雙魚座">
    <option value="不明">
    <option value="不詳">
  </datalist>
  <datalist id="list-blood">
    <option value="A型"><option value="B型"><option value="AB型"><option value="O型"><option value="不明"><option value="不詳">
  </datalist>
  <datalist id="list-lois-relation">
    <option value="D露易絲">
    <option value="E露易絲">
  </datalist>
  <datalist id="list-emotionP">
    <option value="傾倒">
    <option value="好奇心">
    <option value="憧憬">
    <option value="尊敬">
    <option value="連帯感">
    <option value="慈愛">
    <option value="感服">
    <option value="純愛">
    <option value="友情">
    <option value="慕情">
    <option value="同情">
    <option value="遺志">
    <option value="庇護">
    <option value="幸福感">
    <option value="信頼">
    <option value="執着">
    <option value="親近感">
    <option value="誠意">
    <option value="好意">
    <option value="有為">
    <option value="尽力">
    <option value="懐旧">
  </datalist>
  <datalist id="list-emotionN">
    <option value="侮蔑">
    <option value="食傷">
    <option value="脅威">
    <option value="嫉妬">
    <option value="悔悟">
    <option value="恐怖">
    <option value="不安">
    <option value="劣等感">
    <option value="疎外感">
    <option value="恥辱">
    <option value="憐憫">
    <option value="偏愛">
    <option value="憎悪">
    <option value="隔意">
    <option value="嫌悪">
    <option value="猜疑心">
    <option value="厭気">
    <option value="不信感">
    <option value="不快感">
    <option value="憤懣">
    <option value="敵愾心">
    <option value="無関心">
  </datalist>
  <datalist id="list-ride">
    <option value="駕駛:">
    <option value="駕駛:二輪">
    <option value="駕駛:四輪">
    <option value="駕駛:船舶">
    <option value="駕駛:航空器">
    <option value="駕駛:馬">
    <option value="駕駛:多足戰車">
    <option value="駕駛:太空船">
  </datalist>
  <datalist id="list-art" >
    <option value="藝術:">
    <option value="藝術:音樂">
    <option value="藝術:歌唱">
    <option value="藝術:演技">
    <option value="藝術:繪畫">
    <option value="藝術:攝影">
    <option value="藝術:雕刻">
    <option value="藝術:遊戲">
  </datalist>
  <datalist id="list-know">
    <option value="知識:">
    <option value="知識:背教者">
    <option value="知識:醫療">
    <option value="知識:心理">
    <option value="知識:機械工學">
    <option value="知識:機械操作">
    <option value="知識:超自然">
    <option value="知識:遺產">
  </datalist>
  <datalist id="list-info">
    <option value="情報:">
    <option value="情報:UGN">
    <option value="情報:FH">
    <option value="情報:ゼノス">
    <option value="情報:噂話">
    <option value="情報:裏社會">
    <option value="情報:警察">
    <option value="情報:軍事">
    <option value="情報:學問">
    <option value="情報:網路">
    <option value="情報:媒體">
    <option value="情報:商業">
  </datalist>
  <datalist id="list-lois-color">
    <option value="BK">ブラック
    <option value="BL">ブルー
    <option value="GR">グリーン
    <option value="OR">オレンジ
    <option value="PU">パープル
    <option value="RE">レッド
    <option value="WH">ホワイト
    <option value="YE">イエロー
  </datalist>
  <datalist id="list-timing">
    <option value="自動">
    <option value="次要">
    <option value="主要">
    <option value="主要／反應">
    <option value="反應動作">
    <option value="設置階段">
    <option value="先攻階段">
    <option value="清除階段">
    <option value="常駐">
    <option value="參照效果">
  </datalist>
  <datalist id="list-effect-skill">
    <option value="―">
    <option value="症候群">
    <option value="〈近戰〉">
    <option value="〈射擊〉">
    <option value="〈RC〉">
    <option value="〈交涉〉">
    <option value="〈近戰〉〈射擊〉">
    <option value="〈近戰〉〈RC〉">
    <option value="〈迴避〉">
    <option value="〈知覺〉">
    <option value="〈意志〉">
    <option value="〈籌備〉">
    <option value="【肉體】">
    <option value="【感覺】">
    <option value="【精神】">
    <option value="【社會】">
    <option value="〈駕駛:〉">
    <option value="〈藝術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="參照效果">
  </datalist>
  <datalist id="list-combo-timing">
    <option value="自動">
    <option value="次要">
    <option value="主要">
    <option value="反應動作">
    <option value="設置階段">
    <option value="先攻階段">
    <option value="清除階段">
    <option value="常駐">
    <option value="參照效果">
  </datalist>
  <datalist id="list-combo-skill">
    <option value="―">
    <option value="〈近戰〉">
    <option value="〈射擊〉">
    <option value="〈RC〉">
    <option value="〈交涉〉">
    <option value="〈近戰〉〈射擊〉">
    <option value="〈近戰〉〈RC〉">
    <option value="〈迴避〉">
    <option value="〈知覺〉">
    <option value="〈意志〉">
    <option value="〈籌備〉">
    <option value="【肉體】">
    <option value="【感覺】">
    <option value="【精神】">
    <option value="【社會】">
    <option value="〈駕駛:〉">
    <option value="〈藝術:〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="參照效果">
  </datalist>
  <datalist id="list-weapon-skill">
    <option value="―">
    <option value="〈近戰〉">
    <option value="〈射擊〉">
    <option value="〈近戰〉〈射擊〉">
    <option value="〈交涉〉">
    <option value="〈知識:機械工學〉">
    <option value="參照解說">
  </datalist>
  <datalist id="list-vehicle-skill">
    <option value="〈駕駛:〉">
    <option value="〈駕駛:二輪〉">
    <option value="〈駕駛:四輪〉">
    <option value="〈駕駛:船舶〉">
    <option value="〈駕駛:航空器〉">
    <option value="〈駕駛:馬〉">
    <option value="〈駕駛:多足戰車〉">
    <option value="〈駕駛:太空船〉">
  </datalist>
  <datalist id="list-item-skill">
    <option value="―">
    <option value="〈籌備〉">
    <option value="〈知識:〉">
    <option value="〈情報:〉">
    <option value="〈情報:UGN〉">
    <option value="〈情報:FH〉">
    <option value="〈情報:ゼノス〉">
    <option value="〈情報:噂話〉">
    <option value="〈情報:裏社會〉">
    <option value="〈情報:警察〉">
    <option value="〈情報:軍事〉">
    <option value="〈情報:学問〉">
    <option value="〈情報:網路〉">
    <option value="〈情報:媒體〉">
    <option value="〈情報:商業〉">
    <option value="參照解說">
  </datalist>
  <datalist id="list-weapon-type">
    <option value="近戰">
    <option value="射擊">
    <option value="近戰／射擊">
    <option value="紋章／近戰">
    <option value="紋章／射擊">
    <option value="リレーション／近戰">
    <option value="リレーション／射擊">
  </datalist>
  <datalist id="list-armor-type">
    <option value="防具">
    <option value="防具※">
    <option value="防具（補助）">
    <option value="紋章／防具">
    <option value="紋章／防具（補助）">
    <option value="リレーション／防具">
  </datalist>
  <datalist id="list-vehicle-type">
    <option value="ヴィークル">
    <option value="紋章／ヴィークル">
  </datalist>
  <datalist id="list-item-type">
    <option value="關係">
    <option value="一般">
    <option value="その他">
    <option value="使い捨て">
    <option value="紋章／コネ">
    <option value="紋章／一般">
    <option value="紋章／その他">
    <option value="紋章／使い捨て">
    <option value="リレーション／コネ">
    <option value="リレーション／一般">
    <option value="リレーション／その他">
    <option value="リレーション／使い捨て">
  </datalist>
  <datalist id="list-dfclty">
    <option value="―">
    <option value="自動成功">
    <option value="對決">
    <option value="參照效果">
  </datalist>
  <datalist id="list-target">
    <option value="―">
    <option value="自身">
    <option value="單體">
    <option value="3體">
    <option value="[LV+1]體">
    <option value="範圍">
    <option value="範圍（選擇）">
    <option value="場景">
    <option value="場景（選擇）">
    <option value="參照效果">
  </datalist>
  <datalist id="list-range">
    <option value="―">
    <option value="至近">
    <option value="武器">
    <option value="視界">
    <option value="參照效果">
  </datalist>
  <datalist id="list-encroach">
    <option value="―">
    <option value="1">
    <option value="2">
    <option value="3">
    <option value="4">
    <option value="5">
    <option value="6">
    <option value="7">
    <option value="8">
    <option value="10">
    <option value="20">
    <option value="1D10">
    <option value="2D10">
    <option value="4D10">
    <option value="參照效果">
  </datalist>
  <datalist id="list-restrict">
    <option value="―">
    <option value="純血">
    <option value="80%">
    <option value="100%">
    <option value="120%" class="percent120">
    <option value="D露易絲">
    <option value="極限">
    <option value="RB">
    <option value="從者專用">
  </datalist>
  <datalist id="list-magic-type">
    <option value="通常">
    <option value="通常／維持">
    <option value="印形">
    <option value="儀式">
    <option value="儀式／維持">
    <option value="儀式／呪詛">
    <option value="儀式／召喚">
    <option value="召喚">
    <option value="喚起">
    <option value="喚起／儀式">
  </datalist>
  HTML
}
sub renderFooterScript {
  my $html;
  $html .= '<script>';
  $html .= "const makeExp = $set::make_exp;";
  $html .= "const synStats = {";
  foreach (keys %data::syndrome_status) {
    next if !$_;
    my @ar = @{$data::syndrome_status{$_}};
    $html .= qq|"$_":{"body":$ar[0],"sense":$ar[1],"mind":$ar[2],"social":$ar[3]},|;
  }
  $html .= "};\n";
  $html .= "const awakens = {";
  foreach (@data::awakens) {
    next if (@$_[0] =~ /^LABEL=/);
    $html .= qq|"@$_[0]":@$_[1],|;
  }
  $html .= "};\n";
  $html .= 'const impulses = {';
  foreach (@data::impulses) {
    $html .= qq|"@$_[0]":@$_[1],|;
  }
  $html .= "};\n";
  $html .= '</script>';

  return $html;
}

1;
