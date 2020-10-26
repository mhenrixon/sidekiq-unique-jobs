import java.util.*;
import kwalify.*;

public class ExampleAddressBook {
    public static void main(String args[]) throws Exception {
        // read schema
        String schema_str = Util.readFile("address_book.schema.yaml");
        schema_str = Util.untabify(schema_str);
        Object schema = new YamlParser(schema_str).parse();

        // read document file
        String document_str = Util.readFile("address_book.yaml");
        document_str = Util.untabify(document_str);
        YamlParser parser = new YamlParser(document_str);
        Object document = parser.parse();

        // create address book object
        AddressBook addrbook = new AddressBook((Map)document);

        // show groups
        List groups = addrbook.getGroups();
        if (groups != null) {
            for (Iterator it = groups.iterator(); it.hasNext(); ) {
                Group group = (Group)it.next();
                System.out.println("group name: " + group.getName());
                System.out.println("group desc: " + group.getDesc());
                System.out.println();
            }
        }

        // show people
        List people = addrbook.getPeople();
        if (people != null) {
            for (Iterator it = people.iterator(); it.hasNext(); ) {
                Person person = (Person)it.next();
                System.out.println("person name:  " + person.getName());
                System.out.println("person group: " + person.getGroup());
                System.out.println("person email: " + person.getEmail());
                System.out.println("person phone: " + person.getPhone());
                System.out.println("person blood: " + person.getBlood());
                System.out.println("person birth: " + person.getBirth());
                System.out.println();
            }
        }
    }

}
