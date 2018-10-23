package Zera::SC::Components;

use base 'Zera::Base::Components';
use base 'Zera::BaseAdmin::View';
use JSON;

sub component_footer {
    my $self = shift;
    my $limit = shift;
    #my $latest = $self->selectall("SELECT SQL_CACHE new_id, title, DATE_FORMAT(added_on, '%e de %M %Y') AS f_date, url_key FROM news WHERE active=1 ORDER BY added_on DESC limit ?", $limit);
    my $vars = {
     #   latest  => $latest,
 };

 return $self->render_template($vars);
}

sub component_foot_cat {
    my $self = shift;
    #my $categories = $self->selectall("SELECT SQL_CACHE category_id, category, url_key FROM categories WHERE module='News' ORDER BY sort_order");
    my $vars = {
       # categories  => $categories,
   };

   return $self->render_template($vars);
}

sub component_header {
    my $self = shift;
    #my $categories = $self->selectall("SELECT SQL_CACHE category_id, category, url_key FROM categories WHERE module='News' ORDER BY sort_order");
    my $vars = {
      #  categories  => $categories,
  };

  return $self->render_template($vars);
}

sub component_menu {
    my $self = shift;
    my $categories = $self->selectall("SELECT category_id, lower(name) as name, url_key FROM sc_categories WHERE active = 1  and parent_id = 0 ORDER BY sort_order");
    foreach my $category (@$categories){
        $category->{childs}=$self->selectall_arrayref("SELECT category_id, lower(name) as name, url_key FROM sc_categories WHERE active = 1  and parent_id = ?  ORDER BY sort_order",{Slice=>{}},$category->{category_id});
        #$category->{categories}=$self->selectall("SELECT category_id, name, url_key FROM sc_categories WHERE active = 1  and parent_id = 0 ORDER BY sort_order");
        #$category->{hola} = '10';
    }
    my $vars = {
        categories  => $categories,
    };

    return $self->render_template($vars);
}

sub component_footer{
  my $self = shift;
  my $categories = $self->selectall("SELECT category_id, lower(name) as name, url_key FROM sc_categories WHERE active = 1  and parent_id = 0 ORDER BY sort_order");
  foreach my $category (@$categories){
    $category->{childs}=$self->selectall_arrayref("SELECT category_id, lower(name) as name, url_key FROM sc_categories WHERE active = 1  and parent_id = ?  ORDER BY sort_order",{Slice=>{}},$category->{category_id});
        #$category->{categories}=$self->selectall("SELECT category_id, name, url_key FROM sc_categories WHERE active = 1  and parent_id = 0 ORDER BY sort_order");
        #$category->{hola} = '10';
    }
    my $vars = {
        categories  => $categories,
    };

    return $self->render_template($vars);

}
sub component_buscar{
  my $self = shift;
  $self->add_search_box();
  return $self->render_template($vars);

}

1;
