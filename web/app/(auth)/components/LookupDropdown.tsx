"use client";

import { Autocomplete, CircularProgress, TextField } from "@mui/material";
import { useQuery } from "@tanstack/react-query";
import { useDebounce } from "@uidotdev/usehooks";
import { useMemo, useState } from "react";

export type LookupOption = { id: string; name: string };

type LookupDropdownProps = {
  label: string;
  placeholder: string;
  value: LookupOption | null;
  onChange: (option: LookupOption | null) => void;
  fetcher: (query: string) => Promise<LookupOption[]>;
  disabled?: boolean;
  excludeIds?: string[];
  queryKeyPrefix: string;
};

export function LookupDropdown({
  label,
  placeholder,
  value,
  onChange,
  fetcher,
  disabled,
  excludeIds,
  queryKeyPrefix,
}: LookupDropdownProps) {
  const [search, setSearch] = useState(value?.name ?? "");
  const debouncedSearch = useDebounce(search, 300);

  const q = debouncedSearch.trim();
  const shouldFetch = q.length === 0 || q.length >= 3;

  const { data: rawOptions = [], isLoading } = useQuery({
    queryKey: [queryKeyPrefix, q, excludeIds?.sort()?.join(",")],
    queryFn: () => fetcher(q),
    enabled: shouldFetch,
    staleTime: 5 * 60 * 1000,
  });

  const options = useMemo(() => {
    const filtered = rawOptions.filter(
      (item) => !excludeIds?.includes(item.id),
    );
    if (
      value &&
      !excludeIds?.includes(value.id) &&
      !filtered.some((o) => o.id === value.id)
    ) {
      return [{ id: value.id, name: value.name }, ...filtered];
    } else {
      return filtered;
    }
  }, [rawOptions, excludeIds, value]);

  return (
    <Autocomplete
      options={options}
      getOptionLabel={(option) => option.name}
      loading={isLoading}
      value={value}
      onChange={(_, option) => {
        onChange(option ?? null);
        setSearch(option?.name ?? "");
      }}
      inputValue={search}
      onInputChange={(_, val) => setSearch(val)}
      isOptionEqualToValue={(option, val) => option.id === val.id}
      disabled={disabled}
      renderInput={(params) => (
        <TextField
          {...params}
          label={label}
          placeholder={placeholder}
          InputLabelProps={{ shrink: true, required: false }}
          InputProps={{
            ...params.InputProps,
            endAdornment: (
              <>
                {isLoading ? (
                  <CircularProgress color="inherit" size={20} />
                ) : null}
                {params.InputProps.endAdornment}
              </>
            ),
          }}
        />
      )}
    />
  );
}
