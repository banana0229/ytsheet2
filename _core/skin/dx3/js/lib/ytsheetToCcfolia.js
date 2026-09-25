"use strict";

var output = output || {};

output.generateCcfoliaJsonOfDoubleCross3PC = (json, character, defaultPalette) => {
  character.name = json.namePlate || json.characterName || json.aka;
  
  character.memo = '';
  character.memo += json.namePlate?json.characterName+"\n":'';
  character.memo += json.characterNameRuby ? '('+json.characterNameRuby+')\n' :'';
  character.memo += json.aka ? `代號：${json.aka}` : '';
  character.memo += json.aka && json.akaRuby ? ` (${json.akaRuby})` : '';
  //character.memo += `玩家：${json.playerName || '無玩家情報'}\n`;
  character.memo += `\n`;
  character.memo += `${json.works || ''} / ${json.cover || ''}\n`;
  character.memo += `${json.syndrome1 || ''}${json.syndrome2 ? '、'+json.syndrome2 : ''}${json.syndrome3 ? '、'+json.syndrome3 : ''}\n`;
  //character.memo += `\n`;
  //character.memo += `${json.imageURL ? '立繪: ' + (json.imageCopyright || '無版權情報') : ''}`;
  
  character.params = character.params.concat(defaultPalette.parameters || []);

  return character;
};
