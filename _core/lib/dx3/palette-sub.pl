################## チャットパレット用サブルーチン ##################
use strict;
#use warnings;
use utf8;

### プリセット #######################################################################################
sub palettePreset {
  my $tool = shift;
  my $type = shift;
  my $text;
  my %bot;
  if   (!$tool)           { $bot{YTC} = 1; }
  elsif($tool eq 'tekey' ){ $bot{TKY} = $bot{BCD} = 1; }
  elsif($tool eq 'ccfolia'){ $bot{CCF} = $bot{BCD} = 1; }
  elsif($tool eq 'bcdice'){ $bot{BCD} = 1; }
  ## ＰＣ
  if(!$type && $bot{CCF}){
    $text .= "1D 登場侵蝕\n";
    # 數值增減指令
    $text .= ":侵蝕+0 \@+侵蝕\n";
    $text .= ":侵蝕-0 \@-侵蝕\n";
    $text .= ":HP+0 \@+HP\n";
    $text .= ":HP-0 \@-HP\n";
    $text .= ":財產-0 \@-財產\n";
    $text .= ":侵蝕骰數修正=0 \@指定侵蝕骰數修正\n";
  }
  if(!$type){
    # $text .= "//侵蝕率ダイスボーナス=0\n";
    # $text .= "### ■バフ・デバフ\n";
    # $text .= "//ダイス修正=0\n";
    # $text .= "//C値修正=0\n";
    # $text .= "//達成値修正=0\n";
    # $text .= "//攻撃力修正=0\n";
    $text .= "###\n" if $bot{TKY};
    $text .= "### ■判定\n";
    $text .= "\{肉體\}+{DB}dx(10+{CB})+{AB} 【肉體】判定\n";
    $text .= "{感覺}+{DB}dx(10+{CB})+{AB} 【感覺】判定\n";
    $text .= "{精神}+{DB}dx(10+{CB})+{AB} 【精神】判定\n";
    $text .= "{社會}+{DB}dx(10+{CB})+{AB} 【社會】判定\n";
    $text .= "{肉體}+{DB}dx(10+{CB})+{近戰}+{AB} 〈近戰〉判定\n";
    $text .= "{肉體}+{DB}dx(10+{CB})+{迴避}+{AB} 〈迴避〉判定\n";
    $text .= "{感覺}+{DB}dx(10+{CB})+{射擊}+{AB} 〈射擊〉判定\n";
    $text .= "{感覺}+{DB}dx(10+{CB})+{知覺}+{AB} 〈知覺〉判定\n";
    $text .= "{精神}+{DB}dx(10+{CB})+{RC}+{AB} 〈ＲＣ〉判定\n";
    $text .= "{精神}+{DB}dx(10+{CB})+{意志}+{AB} 〈意志〉判定\n";
    $text .= "{社會}+{DB}dx(10+{CB})+{交涉}+{AB} 〈交涉〉判定\n";
    $text .= "{社會}+{DB}dx(10+{CB})+{籌備}+{AB} 〈籌備〉判定\n";
    foreach my $num (1 .. $::pc{skillRideNum}){
      $text .= "{肉體}+{DB}dx(10+{CB})+{$::pc{'skillRide'.$num.'Name'}}+{AB} 〈$::pc{'skillRide'.$num.'Name'}〉判定\n" if $::pc{'skillRide'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{skillArtNum}){
      $text .= "{感覺}+{DB}dx(10+{CB})+{$::pc{'skillArt'.$num.'Name'}}+{AB} 〈$::pc{'skillArt'.$num.'Name'}〉判定\n"  if $::pc{'skillArt'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{skillKnowNum}){
      $text .= "{精神}+{DB}dx(10+{CB})+{$::pc{'skillKnow'.$num.'Name'}}+{AB} 〈$::pc{'skillKnow'.$num.'Name'}〉判定\n" if $::pc{'skillKnow'.$num.'Name'};
    }
    foreach my $num (1 .. $::pc{skillInfoNum}){
      $text .= "{社會}+{DB}dx(10+{CB})+{$::pc{'skillInfo'.$num.'Name'}}+{AB} 〈$::pc{'skillInfo'.$num.'Name'}〉判定\n" if $::pc{'skillInfo'.$num.'Name'};
    }
    $text .= "\n";
    foreach my $num (1 .. $::pc{comboNum}){
      next if !$::pc{'combo'.$num.'Name'};
      $text .= "###\n" if $bot{TKY};
      $text .= "### ■コンボ: ".(removeTags unescapeTags $::pc{'combo'.$num.'Name'})."\n" if($bot{YTC} || $bot{TKY});
      $text .= "【$::pc{'combo'.$num.'Name'}】：$::pc{'combo'.$num.'Combo'}\\n"
            . textTiming($::pc{'combo'.$num.'Timing'})." / $::pc{'combo'.$num.'Skill'} / $::pc{'combo'.$num.'Dfclty'} / $::pc{'combo'.$num.'Target'} / $::pc{'combo'.$num.'Range'}"
            . ($::pc{'combo'.$num.'Note'} ? "\\n$::pc{'combo'.$num.'Note'}" : '')
            ."\n";
      $text .= ($bot{YTC} ? '@侵蝕' : ':侵蝕')  . "+$::pc{'combo'.$num.'Encroach'}\n";
      foreach my $i (1..5) {
        next if !$::pc{'combo'.$num.'Condition'.$i};
        $text .= "▼$::pc{'combo'.$num.'Condition'.$i} ----------\n" if $bot{YTC} || $bot{TKY};
        if(!$::pc{"combo${num}Manual"}){
          if($::pc{"combo${num}Stt"}){
            if   ($::pc{"combo${num}Stt"} eq '肉體'){ $text .= '{肉體}+'; }
            elsif($::pc{"combo${num}Stt"} eq '感覺'){ $text .= '{感覺}+'; }
            elsif($::pc{"combo${num}Stt"} eq '精神'){ $text .= '{精神}+'; }
            elsif($::pc{"combo${num}Stt"} eq '社會'){ $text .= '{社會}+'; }
          }
          else {
            if   ($::pc{"combo${num}Skill"} =~ /^(近戰|迴避|駕駛)/){ $text .= '{肉體}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(射擊|知覺|藝術)/){ $text .= '{感覺}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(RC|意思|知識)/)  { $text .= '{精神}+';  }
            elsif($::pc{"combo${num}Skill"} =~ /^(交涉|籌備|情報)/){ $text .= '{社會}+';  }
          }
        }
        $text .= "$::pc{'combo'.$num.'DiceAdd'.$i}+{DB}dx($::pc{'combo'.$num.'Crit'.$i}+{CB})+$::pc{'combo'.$num.'Fixed'.$i}+{AB}";
        $text .= " 判定／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{BCD} && !$bot{TKY};
        $text .= "\n";
        if($::pc{'combo'.$num.'Atk'.$i} ne ''){
          $text .= "d10+$::pc{'combo'.$num.'Atk'.$i}+{AtkB} ダメージ";
          $text .= "／$::pc{'combo'.$num.'Condition'.$i}／$::pc{'combo'.$num.'Name'}" if $bot{BCD} && !$bot{TKY};
          $text .= "\n";
        }
      }
      $text .= "\n";
    }
  }
  
  $text .= "###\n" if $bot{TKY};
  $text .= "### ■代入式\n";
  $text .= "//DB={侵蝕率ダイスボーナス}+{ダイス修正}\n";
  $text .= "//CB={C値修正}\n";
  $text .= "//AB={達成値修正}\n";
  $text .= "//AtkB={攻撃力修正}\n";
  $text .= "###\n" if $bot{YTC} || $bot{TKY};
  
  if($bot{BCD}) {
    $text =~ s/^(.+?)dx(.+?)(\s|$)/\($1\)dx$2$3/mg;
  }
  
  if(!$type && $bot{CCF}) {
    $text =~ s/(.+?)\+\{DB\}(.*?)dx\(10\+\{CB\}\)(.*?)\+\{AB\}(.*?)(\s|$)/$1\+\{侵蝕骰數修正\}\+0\)DX\(10\-0\)$3$4$5/mg;
    $text .= "\n(0/10+1)D+0+0 \@傷害骰=(命中判定的十位數+1)D+攻擊力+其它修正\n";
    $text .= "C(0-{裝甲值}-0) \@閃躲失敗傷害=HP傷害-裝甲值-其它修正\n";
    $text .= "C(0-{裝甲值}-{格擋值}-0) \@格擋傷害=HP傷害-裝甲值-格擋值-其它修正\n";
  }

  return $text;
}

### プリセット（シンプル） ###########################################################################
sub palettePresetSimple {
  my $tool = shift;
  my $type = shift;
  
  my $text = palettePreset($tool,$type);
  my %propaty;
  foreach (paletteProperties($tool,$type)){
    if($_ =~ /^\/\/(.+?)=(.*)$/){
      $propaty{$1} = $2;
    }
  }
  my $hit = 1;
  while ($hit){
    $hit = 0;
    foreach(keys %propaty){
      if($text =~ s/\{$_\}/$propaty{$_}/i){ $hit = 1 }
    }
  }
  1 while $text =~ s/\([+\-*0-9]+\)/s_eval($&)/egi;
  
  return $text;
}

### デフォルト変数 ###################################################################################
sub paletteProperties {
  my $tool = shift;
  my $type = shift;
  my @propaties;
  push @propaties, "### ■能力値";
  push @propaties, "//肉體=$::pc{sttTotalBody}"  ;
  push @propaties, "//感覺=$::pc{sttTotalSense}" ;
  push @propaties, "//精神=$::pc{sttTotalMind}"  ;
  push @propaties, "//社會=$::pc{sttTotalSocial}";
  push @propaties, "###" if $tool eq 'tekey';
  push @propaties, "### ■技能";
  push @propaties, "//近戰=".($::pc{skillTotalMelee}    ||0);
  push @propaties, "//迴避=".($::pc{skillTotalDodge}    ||0);
  push @propaties, "//射擊=".($::pc{skillTotalRanged}   ||0);
  push @propaties, "//知覺=".($::pc{skillTotalPercept}  ||0);
  push @propaties, "//RC="  .($::pc{skillTotalRC}       ||0);
  push @propaties, "//意志=".($::pc{skillTotalWill}     ||0);
  push @propaties, "//交涉=".($::pc{skillTotalNegotiate}||0);
  push @propaties, "//籌備=".($::pc{skillTotalProcure}  ||0);
  foreach my $name ('Ride','Art','Know','Info'){
    foreach my $num (1 .. $::pc{'skill'.$name.'Num'}){
      next if !$::pc{'skill'.$name.$num.'Name'};
      push @propaties, "//$::pc{'skill'.$name.$num.'Name'}=".($::pc{'skillTotal'.$name.$num}||0);
    }
  }
  return @propaties;
}

sub textTiming {
  my $text = shift;
  $text =~ s/(オート|メジャー|マイナー)(アクション)?/$1アクション/g;
  $text =~ s/リアク?(ション)?/リアクション/g;
  $text =~ s/(セットアップ|クリンナップ)(プロセス)?/$1プロセス/g;
  return $text;
}

1;