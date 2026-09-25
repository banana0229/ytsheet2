################## JSONデータ追加 ##################
use strict;
#use warnings;
use utf8;
use open ":utf8";

sub addJsonData {
  my %pc = %{ $_[0] };
  my $type = $_[1];

  ## ロイス数
  my @dloises; $pc{loisHave} = 0; $pc{loisMax} = 0; $pc{titusHave} = 0; $pc{sublimated} = 0;
  foreach my $num (1..7){
    if($pc{"lois${num}Relation"} =~ /[DＤEＥ]露易絲|^[DＤEＥ]$/){
      $pc{"lois${num}Name"} =~ s#/#／#g;
      push(@dloises, $pc{"lois${num}Name"});
    }
    else {
      if($pc{"lois${num}State"} =~ /泰特斯/){
        $pc{titusHave}++;
      }
      elsif($pc{"lois${num}State"} =~ /昇華/){
        $pc{sublimated}++;
      }
      else{
        $pc{loisMax}++;
        $pc{loisHave}++ if($pc{"lois${num}Name"});
      }
    }
  }
  ## 簡易プロフィール
  my @classes;
  foreach (@data::class_names){
    push(@classes, { "NAME" => $_, "LV" => $pc{'lv'.$data::class{$_}{id}} } );
  }
  @classes = sort{$b->{LV} <=> $a->{LV}} @classes;
  my $class_text;
  foreach my $data (@classes){
    $class_text .= ($class_text ? '／' : '') . $data->{NAME} . $data->{LV} if $data->{LV} > 0;
  }
  my $base = "性別:$pc{gender}　年齡:$pc{age}";
  my $sub  = "身高:$pc{height}　體重:$pc{weight}";
  my $works = "真身:$pc{works}　表面:$pc{cover}";
  my $syndrome = "症候群:$pc{syndrome1}"
               . ($pc{syndrome2}?"／$pc{syndrome2}":'')
               . ($pc{syndrome3}?"／$pc{syndrome3}":'');
  my $dlois = (@dloises ? 'D露易絲:'.join('／', @dloises) : '');

  $pc{sheetDescriptionS} = $base."\n".$works."\n".$syndrome;
  $pc{sheetDescriptionM} = $base."　".$sub."\n".$works."\n".$syndrome.($dlois?"\n$dlois":'');

  ## ユニット（コマ）用ステータス
  $pc{unitStatus} = createUnitStatus(\%pc);

  return \%pc;
}

1;
