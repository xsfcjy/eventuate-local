package io.eventuate.local.postgres.wal;

import io.eventuate.local.common.BinlogFileOffset;
import io.eventuate.local.common.PublishedEvent;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public class PostgresWalJsonMessageParser implements PostgresWalMessageParser<PublishedEvent> {

  @Override
  public List<PublishedEvent> parse(PostgresWalMessage message, long lastSequenceNumber, String slotName) {
    List<PostgresWalChange> changes = Arrays.asList(message.getChange());

    return changes
            .stream()
            .filter(change -> change.getKind().equals("insert") && change.getTable().equals("events"))
            .map(insertedEvent -> {
              List<String> columns = Arrays.asList(insertedEvent.getColumnnames());

              int id = columns.indexOf("event_id");
              int entityId = columns.indexOf("entity_id");
              int entityType = columns.indexOf("entity_type");
              int eventDate = columns.indexOf("event_data");
              int eventType = columns.indexOf("event_type");
              int metadata = columns.indexOf("metadata");

              List<String> values = Arrays.asList(insertedEvent.getColumnvalues());

              return new PublishedEvent(values.get(id),
                      values.get(entityId),
                      values.get(entityType),
                      values.get(eventDate),
                      values.get(eventType),
                      new BinlogFileOffset(slotName, lastSequenceNumber),
                      Optional.ofNullable(values.get(metadata)));
            })
            .collect(Collectors.toList());
  }
}
