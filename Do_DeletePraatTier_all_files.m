function Do_DeletePraatTier_all_files(tier)
% 'tgFName': TextGrid filename.
% Weirong Chen  Apr-21-2015
fl = gfl([pwd filesep '*.TextGrid']);
for i = 1:numel(fl)
    fn = [pwd filesep fl{i} '.TextGrid'];
    DeletePraatTier(fn, tier);
end
end % 