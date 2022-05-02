(*
  (C)2021-2022 Magno Lima - www.MagnumLabs.com.br

  THIS IS A TEST FILE TO USE WITH OPENAI GPT-3 API
  ** YOU WILL NEED YOUR OWN KEY TO BE ABLE TO USE THIS SOFTWARE **

  Delphi libraries for using OpenAI's GPT-3 api

  This library is licensed under Creative Commons CC-0 (aka CC Zero),
  which means that this a public dedication tool, which allows creators to
  give up their copyright and put their works into the worldwide public domain.
  You're allowed to distribute, remix, adapt, and build upon the material
  in any medium or format, with no conditions.

  Feel free to open a push request if there's anything you want
  to contribute.

  https://beta.openai.com/docs/api-reference/engines/retrieve
*)
unit uDemoAI21;

interface

uses
   System.SysUtils, System.Types, System.UITypes, System.Classes,
   System.Variants,
   FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, System.IOUtils,
   FMX.StdCtrls, FMX.Controls.Presentation, FireDAC.Stan.Intf,
   FireDAC.Stan.Option, FireDAC.Stan.Param, FireDAC.Stan.Error, FireDAC.DatS,
   FireDAC.Phys.Intf, FireDAC.DApt.Intf, System.Rtti, FMX.Grid.Style,
   Data.Bind.EngExt, FMX.Bind.DBEngExt, FMX.Bind.Grid, System.Bindings.Outputs,
   FMX.Bind.Editors, Data.Bind.Components, Data.Bind.Grid, Data.Bind.DBScope,
   Data.DB, FMX.Grid, FireDAC.Comp.DataSet, FireDAC.Comp.Client, FMX.ScrollBox,
   FMX.Memo, FMX.Edit, Data.Bind.ObjectScope, REST.Client, REST.Response.Adapter,
   FMX.Objects, FMX.TabControl, FMX.EditBox, FMX.NumberBox, FMX.Memo.Types,
   REST.Types, System.Generics.Collections,
   MLAI21.Types;

const
   APIKey_Filename = '.\ai21.key';

type
   TfrmDemoAI21 = class(TForm)
      ToolBar1: TToolBar;
      mmPrompt: TMemo;
      FDMemTable1: TFDMemTable;
      DataSource1: TDataSource;
      BindingsList1: TBindingsList;
      Label1: TLabel;
      Button1: TButton;
      Panel1: TPanel;
      AniIndicator1: TAniIndicator;
      TabControl1: TTabControl;
      TabItem2: TTabItem;
      Label3: TLabel;
      Label4: TLabel;
      Edit1: TEdit;
      Label8: TLabel;
      Memo2: TMemo;
      RESTClient1: TRESTClient;
      RESTRequest1: TRESTRequest;
      RESTResponse1: TRESTResponse;
      Button2: TButton;
      ToolBar2: TToolBar;
      lbEngine: TLabel;
      Image1: TImage;
      rbTJ1Grande: TRadioButton;
      rbJ1Jumbo: TRadioButton;
      rbJ1Large: TRadioButton;
      tbTemperature: TTrackBar;
      Label5: TLabel;
      nbMaxTokens: TTrackBar;
      nbTopP: TTrackBar;
      Label2: TLabel;
      Label6: TLabel;
      Label7: TLabel;
      Label9: TLabel;
      procedure FormCreate(Sender: TObject);
      procedure FormDestroy(Sender: TObject);
      procedure Button1Click(Sender: TObject);
      procedure rbEngineSelect(Sender: TObject);
      procedure FormShow(Sender: TObject);
      procedure Button2Click(Sender: TObject);
      procedure nbMaxTokensChange(Sender: TObject);
      procedure tbTemperatureChange(Sender: TObject);
      procedure nbTopPChange(Sender: TObject);
   private
      procedure InitCompletions;
      procedure OnOpenAIError(Sender: TObject);
      { Private declarations }
   public
      { Public declarations }
      procedure OnOpenAIResponse(Sender: TObject);
   end;

var
   frmDemoAI21: TfrmDemoAI21;
   EngineIndex: Integer;
   NameOfEngines: TArray<String>;

implementation

uses
   System.JSON,
   MLAI21.Core, MLAI21.Complete;

var
   AI21: TAI21;

{$R *.fmx}

function SliceString(const AString: string; const ADelimiter: string): TArray<String>;
var
   I: Integer;
   p: ^Integer;
   PLine, PStart: PChar;
   s: String;
begin

   I := 1;
   PLine := PChar(AString);

   PStart := PLine;
   inc(PLine);

   while (I < length(AString)) do
   begin
      while (PLine^ <> #0) and (PLine^ <> ADelimiter) do
      begin
         inc(PLine);
         inc(I);
      end;

      SetString(s, PStart, PLine - PStart);
      SetLength(Result, length(Result) + 1);
      Result[length(Result) - 1] := s;
      inc(PLine);
      inc(I);
      PStart := PLine;
   end;

end;

procedure TfrmDemoAI21.OnOpenAIError(Sender: TObject);
begin
   if AI21.StatusCode = 422 then
      Memo2.Lines.Add('Unprocessed error, check your parameters. Error 422.')
   else
      Memo2.Lines.Add('Error ' + AI21.StatusCode.ToString + ' - ' + AI21.ErrorMessage);
end;

procedure TfrmDemoAI21.FormCreate(Sender: TObject);
begin
   NameOfEngines := TAI21EngineName;
   // Store your key safely. Never share or expose it!
   AI21 := TAI21.Create(FDMemTable1, APIKey_Filename);
   AI21.Endpoint := AI21_ENDPOINT;
   AI21.Engine := TAI21Engine.egJ1Grande;
   AI21.OnResponse := OnOpenAIResponse;
   AI21.OnError := OnOpenAIError;
   EngineIndex := Ord(AI21.Engine);
end;

procedure TfrmDemoAI21.FormDestroy(Sender: TObject);
begin
   AI21.DisposeOf;
end;

procedure TfrmDemoAI21.Button2Click(Sender: TObject);
begin
   Memo2.Lines.Clear;
end;

procedure TfrmDemoAI21.FormShow(Sender: TObject);
begin
   AI21.RequestType := orComplete;
   lbEngine.Text := 'Engine: ' + NameOfEngines[Ord(EngineIndex)];
end;

function IfThen(const Test: Boolean; IsTrue, IsFalse: String): String;
begin
   if Test then
      Result := IsTrue
   else
      Result := IsFalse;
end;

procedure TfrmDemoAI21.OnOpenAIResponse(Sender: TObject);
var
   field: TField;
	Engine: TPair<string, string>;
begin
   Button1.Enabled := True;
   AniIndicator1.Enabled := False;

	Memo2.Lines.Add('Record count = ' + FDMemTable1.RecordCount.ToString);
   while not FDMemTable1.Eof do
	begin
      Memo2.Lines.Add('{');
      for field in FDMemTable1.Fields do
         Memo2.Lines.Add(field.FieldName + ': "' + Trim(field.AsString) + '"' + IfThen(field.Index = FDMemTable1.Fields.Count - 1,
           '', ','));
      Memo2.Lines.Add('}');
      FDMemTable1.Next;
   end;

end;

procedure TfrmDemoAI21.rbEngineSelect(Sender: TObject);
begin
   EngineIndex := (Sender as TRadioButton).Tag;
   lbEngine.Text := 'Engine: ' + NameOfEngines[Ord(EngineIndex)];
end;

procedure TfrmDemoAI21.tbTemperatureChange(Sender: TObject);
begin
   Label7.Text := Format('%0.2f', [tbTemperature.Value]);
end;

procedure TfrmDemoAI21.InitCompletions;
var
   ACompletions: TComplete;
   I: Integer;
   sPrompt: String;

   function getStops(Text: String): TArray<String>;
   begin
      Result := SliceString(Text, ';');
   end;

begin

   sPrompt := mmPrompt.Text.Trim;

   if sPrompt.IsEmpty then
   begin
      ShowMessage('A prompt text must be supplied');
      Exit;
   end;

   ACompletions := TComplete.Create(EngineIndex);
   ACompletions.MaxTokens := Round(nbMaxTokens.Value);
   ACompletions.SamplingTemperature := tbTemperature.Value;
   ACompletions.TopP := nbTopP.Value;
   ACompletions.Stop := getStops(Edit1.Text);
   ACompletions.Prompt := sPrompt;
   ACompletions.LogProbabilities := -1; // -1 will set as null default

   AI21.Completions := ACompletions;

   case EngineIndex of
      0:
         AI21.Engine := TAI21Engine.egJ1Large;
      1:
         AI21.Engine := TAI21Engine.egJ1Grande;
      2:
         AI21.Engine := TAI21Engine.egJ1Jumbo;
   end;

   AI21.RequestType := orComplete;
   AI21.Endpoint := AI21_ENDPOINT + NameOfEngines[EngineIndex];

end;

procedure TfrmDemoAI21.nbMaxTokensChange(Sender: TObject);
begin
   Label6.Text := Round(nbMaxTokens.Value).ToString;
end;

procedure TfrmDemoAI21.nbTopPChange(Sender: TObject);
begin
   Label9.Text := Format('%0.2f', [nbTopP.Value]);
end;

procedure TfrmDemoAI21.Button1Click(Sender: TObject);
begin
   if AI21.APIKey.IsEmpty then
   begin
      Memo2.Lines.Add('API key is missing');
      Exit;
   end;

   if (AI21.RequestType = orComplete) and (mmPrompt.Text.IsEmpty) then
   begin
      Memo2.Lines.Add('The prompt can''t be empty');
      mmPrompt.SetFocus;
      Exit;
   end;

   if AI21.RequestType = orNone then
   begin
      Memo2.Lines.Add('Choose a request type.');
      Exit;
   end;

   Button1.Enabled := False;
   AniIndicator1.Enabled := True;
   AniIndicator1.Visible := True;

   TThread.CreateAnonymousThread(
      procedure
      begin
         try
            InitCompletions();

            try
               AI21.Execute;
            except
               on E: Exception do
                  Memo2.Lines.Add(E.Message)
            end;

         finally
            Button1.Enabled := True;
            AniIndicator1.Enabled := False;
            AniIndicator1.Visible := False;
         end;

      end).Start;
end;

end.
